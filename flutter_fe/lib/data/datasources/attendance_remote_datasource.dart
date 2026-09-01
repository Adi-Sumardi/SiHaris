import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:gaji_pro/core/constants/variables.dart';
import 'package:gaji_pro/core/services/connectivity_service.dart';
import 'package:gaji_pro/core/services/http_logger.dart';
import 'package:gaji_pro/core/services/offline_attendance/offline_attendance_service.dart';
import 'package:gaji_pro/core/services/secure_storage_service.dart';
import 'package:gaji_pro/core/services/session_service.dart';
import 'package:gaji_pro/core/utils/error_parser.dart';
import 'package:gaji_pro/data/datasources/auth_datasource.dart';
import 'package:gaji_pro/data/datasources/auth_local_datasource.dart';
import 'package:gaji_pro/data/models/requests/clock_in_request_model.dart';
import 'package:gaji_pro/data/models/requests/clock_out_request_model.dart';
import 'package:gaji_pro/data/models/responses/attendance_history_model.dart';
import 'package:gaji_pro/data/models/responses/attendance_summary_model.dart';
import 'package:gaji_pro/data/models/responses/attendance_today_model.dart';

class AttendanceRemoteDatasource implements AttendanceUploader {
  final http.Client _client;
  final AuthLocalDatasourceBase _localDatasource;
  final ConnectivityService _connectivity;
  final OfflineAttendanceService _offline;
  final SecureStorageService _secureStorage;

  AttendanceRemoteDatasource({
    http.Client? client,
    AuthLocalDatasourceBase? localDatasource,
    ConnectivityService? connectivity,
    OfflineAttendanceService? offline,
    SecureStorageService? secureStorage,
  }) : _client = client ?? http.Client(),
       _localDatasource = localDatasource ?? AuthLocalDatasource(),
       _connectivity = connectivity ?? ConnectivityServiceImpl(),
       _offline = offline ?? OfflineAttendanceService.instance,
       _secureStorage = secureStorage ?? SecureStorageService.instance;

  Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Either<String, AttendanceTodayModel>> getTodayAttendance() async {
    try {
      final token = await _localDatasource.getToken();
      if (token == null) return const Left('Anda belum login');

      final response = await _client.get(
        Uri.parse(Variables.attendanceToday),
        headers: _getHeaders(token),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final data = body['data'] as Map<String, dynamic>?;
        final scheduleJson = body['schedule'] as Map<String, dynamic>?;
        final schedule = scheduleJson != null ? Schedule.fromJson(scheduleJson) : null;
        if (data != null) {
          final model = AttendanceTodayModel.fromJson(data);
          return Right(model.schedule == null && schedule != null
              ? AttendanceTodayModel(
                  id: model.id,
                  date: model.date,
                  clockIn: model.clockIn,
                  clockOut: model.clockOut,
                  status: model.status,
                  statusLabel: model.statusLabel,
                  lateMinutes: model.lateMinutes,
                  workingMinutes: model.workingMinutes,
                  faceVerified: model.faceVerified,
                  officeLocation: model.officeLocation,
                  schedule: schedule,
                )
              : model);
        }
        return Right(AttendanceTodayModel.empty(schedule: schedule));
      } else if (response.statusCode == 401) {
        SessionService.instance.handleSessionExpired();
        return const Left('Sesi Anda telah berakhir');
      } else {
        return Left(ErrorParser.parse(body, fallback: 'Gagal memuat absensi hari ini'));
      }
    } catch (e) {
      return Left(ErrorParser.parseException(e));
    }
  }

  // ===========================================================================
  // Offline-aware public API (dipanggil BLoC)
  // ===========================================================================

  /// Clock-in. Jika perangkat offline atau koneksi putus saat mengirim,
  /// absensi disimpan ke antrean lokal dan dikirim otomatis saat online.
  Future<Either<String, Map<String, dynamic>>> clockIn(
    ClockInRequestModel request,
  ) async {
    if (!await _connectivity.isOnline()) {
      await _offline.enqueueClockIn(request);
      return Right(_offlineSavedBody(isClockIn: true));
    }
    try {
      return await _performClockIn(request);
    } on SocketException {
      await _offline.enqueueClockIn(request);
      return Right(_offlineSavedBody(isClockIn: true));
    } on http.ClientException {
      await _offline.enqueueClockIn(request);
      return Right(_offlineSavedBody(isClockIn: true));
    }
  }

  /// Clock-out dengan perilaku offline-aware yang sama dengan [clockIn].
  Future<Either<String, Map<String, dynamic>>> clockOut(
    ClockOutRequestModel request,
  ) async {
    if (!await _connectivity.isOnline()) {
      await _offline.enqueueClockOut(request);
      return Right(_offlineSavedBody(isClockIn: false));
    }
    try {
      return await _performClockOut(request);
    } on SocketException {
      await _offline.enqueueClockOut(request);
      return Right(_offlineSavedBody(isClockIn: false));
    } on http.ClientException {
      await _offline.enqueueClockOut(request);
      return Right(_offlineSavedBody(isClockIn: false));
    }
  }

  Map<String, dynamic> _offlineSavedBody({required bool isClockIn}) => {
        'offline': true,
        'message':
            'Tidak ada koneksi internet. Absensi ${isClockIn ? 'masuk' : 'pulang'} disimpan dan akan dikirim otomatis saat kembali online.',
      };

  // --- AttendanceUploader (dipakai saat sinkronisasi antrean) ---

  @override
  Future<bool> uploadClockIn(ClockInRequestModel request) async {
    final result = await _performClockIn(request);
    return result.isRight();
  }

  @override
  Future<bool> uploadClockOut(ClockOutRequestModel request) async {
    final result = await _performClockOut(request);
    return result.isRight();
  }

  /// Sinkronkan semua absensi offline yang tertunda ke server.
  Future<int> syncPendingAttendance() => _offline.sync(this);

  // ===========================================================================
  // Raw network calls
  // ===========================================================================

  Future<Either<String, Map<String, dynamic>>> _performClockIn(
    ClockInRequestModel request,
  ) async {
    try {
      final token = await _localDatasource.getToken();
      if (token == null) return const Left('Anda belum login');

      final uri = Uri.parse(Variables.attendanceClockIn);
      final multipartRequest = http.MultipartRequest('POST', uri);

      multipartRequest.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      multipartRequest.fields['latitude'] = request.latitude.toString();
      multipartRequest.fields['longitude'] = request.longitude.toString();
      multipartRequest.fields['office_location_id'] = request.officeLocationId
          .toString();
      multipartRequest.fields['gps_verified'] = request.gpsVerified ? '1' : '0';
      multipartRequest.fields['face_verified'] = request.faceVerified
          ? '1'
          : '0';
      multipartRequest.fields['liveness_passed'] = request.livenessPassed
          ? '1'
          : '0';
      // Required by the backend's device-binding anti-fraud check: one
      // device can only ever be used to clock in for a single employee.
      multipartRequest.fields['app_device_id'] =
          await _secureStorage.getOrCreateDeviceId();

      if (request.notes != null) {
        multipartRequest.fields['notes'] = request.notes!;
      }
      if (request.faceConfidence != null) {
        multipartRequest.fields['face_confidence'] = request.faceConfidence.toString();
      }
      if (request.faceDescriptors != null && request.faceDescriptors!.length == 128) {
        multipartRequest.fields['face_descriptors'] = jsonEncode(request.faceDescriptors!);
      }

      if (request.photo != null) {
        multipartRequest.files.add(
          await http.MultipartFile.fromPath('photo', request.photo!.path),
        );
      }

      HttpLogger.logRequest(
        method: 'POST',
        url: uri.toString(),
        headers: multipartRequest.headers,
        body: multipartRequest.fields,
      );

      final stopwatch = Stopwatch()..start();
      final streamedResponse = await _client.send(multipartRequest);
      final response = await http.Response.fromStream(streamedResponse);
      stopwatch.stop();

      HttpLogger.logResponse(
        method: 'POST',
        url: uri.toString(),
        statusCode: response.statusCode,
        body: response.body,
        duration: stopwatch.elapsed,
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Right(body);
      } else if (response.statusCode == 401) {
        SessionService.instance.handleSessionExpired();
        return const Left('Sesi Anda telah berakhir');
      } else {
        return Left(body['message'] ?? 'Clock in failed');
      }
    } on SocketException {
      // Diteruskan agar pemanggil (clockIn) menyimpannya ke antrean offline.
      rethrow;
    } on http.ClientException {
      // Diteruskan agar pemanggil (clockIn) menyimpannya ke antrean offline.
      rethrow;
    } catch (e, stackTrace) {
      HttpLogger.logError(
        method: 'POST',
        url: Variables.attendanceClockIn,
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ErrorParser.parseException(e));
    }
  }

  Future<Either<String, Map<String, dynamic>>> _performClockOut(
    ClockOutRequestModel request,
  ) async {
    try {
      final token = await _localDatasource.getToken();
      if (token == null) return const Left('Anda belum login');

      final uri = Uri.parse(Variables.attendanceClockOut);
      final multipartRequest = http.MultipartRequest('POST', uri);

      multipartRequest.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      multipartRequest.fields['latitude'] = request.latitude.toString();
      multipartRequest.fields['longitude'] = request.longitude.toString();
      multipartRequest.fields['office_location_id'] = request.officeLocationId
          .toString();
      multipartRequest.fields['gps_verified'] = request.gpsVerified ? '1' : '0';
      multipartRequest.fields['face_verified'] = request.faceVerified
          ? '1'
          : '0';
      multipartRequest.fields['liveness_passed'] = request.livenessPassed
          ? '1'
          : '0';
      // Required by the backend's device-binding anti-fraud check: one
      // device can only ever be used to clock in/out for a single employee.
      multipartRequest.fields['app_device_id'] =
          await _secureStorage.getOrCreateDeviceId();

      if (request.notes != null) {
        multipartRequest.fields['notes'] = request.notes!;
      }
      if (request.faceConfidence != null) {
        multipartRequest.fields['face_confidence'] = request.faceConfidence
            .toString();
      }
      if (request.faceDescriptors != null && request.faceDescriptors!.length == 128) {
        multipartRequest.fields['face_descriptors'] = jsonEncode(request.faceDescriptors!);
      }

      if (request.photo != null) {
        multipartRequest.files.add(
          await http.MultipartFile.fromPath('photo', request.photo!.path),
        );
      }

      HttpLogger.logRequest(
        method: 'POST',
        url: uri.toString(),
        headers: multipartRequest.headers,
        body: multipartRequest.fields,
      );

      final stopwatch = Stopwatch()..start();
      final streamedResponse = await _client.send(multipartRequest);
      final response = await http.Response.fromStream(streamedResponse);
      stopwatch.stop();

      HttpLogger.logResponse(
        method: 'POST',
        url: uri.toString(),
        statusCode: response.statusCode,
        body: response.body,
        duration: stopwatch.elapsed,
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Right(body);
      } else if (response.statusCode == 401) {
        SessionService.instance.handleSessionExpired();
        return const Left('Sesi Anda telah berakhir');
      } else {
        return Left(ErrorParser.parse(body, fallback: 'Clock out gagal'));
      }
    } on SocketException {
      // Diteruskan agar pemanggil (clockOut) menyimpannya ke antrean offline.
      rethrow;
    } on http.ClientException {
      // Diteruskan agar pemanggil (clockOut) menyimpannya ke antrean offline.
      rethrow;
    } catch (e, stackTrace) {
      HttpLogger.logError(
        method: 'POST',
        url: Variables.attendanceClockOut,
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ErrorParser.parseException(e));
    }
  }

  Future<Either<String, List<AttendanceHistoryModel>>> getHistory({
    int page = 1,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final token = await _localDatasource.getToken();
      if (token == null) return const Left('Anda belum login');

      var uri = Uri.parse(Variables.attendanceHistory).replace(
        queryParameters: {
          'page': page.toString(),
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
        },
      );

      final response = await _client.get(uri, headers: _getHeaders(token));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final list = body['data'] as List?;
        if (list != null) {
          return Right(
            list.map((e) => AttendanceHistoryModel.fromJson(e)).toList(),
          );
        }
        return const Right([]);
      } else if (response.statusCode == 401) {
        SessionService.instance.handleSessionExpired();
        return const Left('Sesi Anda telah berakhir');
      } else {
        return Left(ErrorParser.parse(body, fallback: 'Gagal memuat riwayat absensi'));
      }
    } catch (e) {
      return Left(ErrorParser.parseException(e));
    }
  }

  Future<Either<String, AttendanceSummaryModel>> getSummary({
    required int month,
    required int year,
  }) async {
    try {
      final token = await _localDatasource.getToken();
      if (token == null) return const Left('Anda belum login');

      var uri = Uri.parse(Variables.attendanceSummary).replace(
        queryParameters: {'month': month.toString(), 'year': year.toString()},
      );

      final response = await _client.get(uri, headers: _getHeaders(token));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return Right(AttendanceSummaryModel.fromJson(data));
        }
        return const Left('Data tidak ditemukan');
      } else if (response.statusCode == 401) {
        SessionService.instance.handleSessionExpired();
        return const Left('Sesi Anda telah berakhir');
      } else {
        return Left(ErrorParser.parse(body, fallback: 'Gagal memuat ringkasan absensi'));
      }
    } catch (e) {
      return Left(ErrorParser.parseException(e));
    }
  }
}
