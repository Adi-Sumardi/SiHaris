import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:gaji_pro/core/constants/variables.dart';
import 'package:gaji_pro/core/services/session_service.dart';
import 'package:gaji_pro/data/models/requests/face_recognition/face_enroll_request_model.dart';
import 'package:gaji_pro/data/models/requests/face_recognition/face_verify_request_model.dart';
import 'package:gaji_pro/data/models/responses/face_recognition/face_recognition_status_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

abstract class FaceRecognitionDatasource {
  Future<Either<String, FaceRecognitionStatusModel>> getStatus();
  Future<Either<String, FaceEnrollResponseModel>> enroll(FaceEnrollRequestModel request);
  Future<Either<String, FaceVerifyResponseModel>> verify(FaceVerifyRequestModel request);
  Future<Either<String, bool>> deleteEnrollment();
}

class FaceRecognitionRemoteDatasource implements FaceRecognitionDatasource {
  final http.Client client;

  FaceRecognitionRemoteDatasource({required this.client});

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<Either<String, FaceRecognitionStatusModel>> getStatus() async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse(Variables.faceRecognitionStatus),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        // API returns { "data": { ... } }
        final data = json['data'] as Map<String, dynamic>? ?? json;
        return Right(FaceRecognitionStatusModel.fromJson(data));
      } else if (response.statusCode == 401) {
        SessionService.instance.handleSessionExpired();
        return const Left('Sesi Anda telah berakhir');
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Left(json['message'] as String? ?? 'Terjadi kesalahan');
      }
    } catch (e) {
      return Left('Terjadi kesalahan: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, FaceEnrollResponseModel>> enroll(FaceEnrollRequestModel request) async {
    try {
      final headers = await _getHeaders();
      final body = request.toJson();

      final response = await client.post(
        Uri.parse(Variables.faceRecognitionEnroll),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Right(FaceEnrollResponseModel.fromJson(json));
      } else if (response.statusCode == 401) {
        SessionService.instance.handleSessionExpired();
        return const Left('Sesi Anda telah berakhir');
      } else if (response.statusCode == 422) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final errors = json['errors'] as Map<String, dynamic>?;
        if (errors != null) {
          final firstError = errors.values.first as List;
          return Left(firstError.first as String);
        }
        return Left(json['message'] as String? ?? 'Data tidak valid');
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Left(json['message'] as String? ?? 'Terjadi kesalahan');
      }
    } catch (e) {
      return Left('Terjadi kesalahan: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, FaceVerifyResponseModel>> verify(FaceVerifyRequestModel request) async {
    try {
      final headers = await _getHeaders();
      final body = request.toJson();

      final response = await client.post(
        Uri.parse(Variables.faceRecognitionVerify),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Right(FaceVerifyResponseModel.fromJson(json));
      } else if (response.statusCode == 401) {
        SessionService.instance.handleSessionExpired();
        return const Left('Sesi Anda telah berakhir');
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Left(json['message'] as String? ?? 'Terjadi kesalahan');
      }
    } catch (e) {
      return Left('Terjadi kesalahan: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, bool>> deleteEnrollment() async {
    try {
      final headers = await _getHeaders();
      final response = await client.delete(
        Uri.parse(Variables.faceRecognitionEnrollment),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return const Right(true);
      } else if (response.statusCode == 401) {
        SessionService.instance.handleSessionExpired();
        return const Left('Sesi Anda telah berakhir');
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Left(json['message'] as String? ?? 'Terjadi kesalahan');
      }
    } catch (e) {
      return Left('Terjadi kesalahan: ${e.toString()}');
    }
  }
}
