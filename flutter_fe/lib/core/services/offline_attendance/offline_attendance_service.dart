import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../data/models/requests/clock_in_request_model.dart';
import '../../../data/models/requests/clock_out_request_model.dart';
import 'attendance_queue_db.dart';
import 'pending_attendance.dart';

/// Abstraksi minimal pengirim absensi ke server (raw, tanpa logika offline),
/// dipakai saat sinkronisasi antrean.
abstract class AttendanceUploader {
  /// Kirim clock-in langsung ke server. `true` jika sukses tersimpan di server.
  Future<bool> uploadClockIn(ClockInRequestModel request);

  /// Kirim clock-out langsung ke server. `true` jika sukses tersimpan di server.
  Future<bool> uploadClockOut(ClockOutRequestModel request);
}

/// Mengelola antrean absensi offline: menyimpan saat tidak ada koneksi dan
/// menyinkronkannya kembali ketika online.
class OfflineAttendanceService {
  OfflineAttendanceService._();
  static final OfflineAttendanceService instance = OfflineAttendanceService._();

  final AttendanceQueueDb _db = AttendanceQueueDb.instance;

  /// Jumlah absensi yang masih menunggu sinkronisasi (untuk badge UI).
  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  bool _syncing = false;

  Future<void> refreshCount() async {
    pendingCount.value = await _db.count();
  }

  /// Simpan clock-in untuk dikirim nanti. Foto disalin ke folder aplikasi agar
  /// tidak terhapus oleh OS dari cache kamera sebelum sempat tersinkron.
  Future<void> enqueueClockIn(ClockInRequestModel request) async {
    await _enqueue(
      type: PendingAttendanceType.clockIn,
      latitude: request.latitude,
      longitude: request.longitude,
      officeLocationId: request.officeLocationId,
      gpsVerified: request.gpsVerified,
      faceVerified: request.faceVerified,
      faceConfidence: request.faceConfidence,
      notes: request.notes,
      photo: request.photo,
    );
  }

  Future<void> enqueueClockOut(ClockOutRequestModel request) async {
    await _enqueue(
      type: PendingAttendanceType.clockOut,
      latitude: request.latitude,
      longitude: request.longitude,
      officeLocationId: request.officeLocationId,
      gpsVerified: request.gpsVerified,
      faceVerified: request.faceVerified,
      faceConfidence: request.faceConfidence,
      notes: request.notes,
      photo: request.photo,
    );
  }

  Future<void> _enqueue({
    required PendingAttendanceType type,
    required double latitude,
    required double longitude,
    required int officeLocationId,
    required bool gpsVerified,
    required bool faceVerified,
    double? faceConfidence,
    String? notes,
    File? photo,
  }) async {
    final persistedPhotoPath = await _persistPhoto(photo);
    await _db.insert(PendingAttendance(
      type: type,
      latitude: latitude,
      longitude: longitude,
      officeLocationId: officeLocationId,
      gpsVerified: gpsVerified,
      faceVerified: faceVerified,
      faceConfidence: faceConfidence,
      notes: notes,
      photoPath: persistedPhotoPath,
      createdAt: DateTime.now(),
    ));
    await refreshCount();
  }

  /// Salin foto ke direktori dokumen aplikasi; kembalikan path baru.
  Future<String?> _persistPhoto(File? photo) async {
    if (photo == null || !photo.existsSync()) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final offlineDir = Directory(p.join(dir.path, 'offline_attendance'));
      if (!offlineDir.existsSync()) offlineDir.createSync(recursive: true);
      final fileName =
          'att_${DateTime.now().millisecondsSinceEpoch}${p.extension(photo.path)}';
      final newPath = p.join(offlineDir.path, fileName);
      await photo.copy(newPath);
      return newPath;
    } catch (_) {
      // Jika gagal menyalin, simpan path asli sebagai fallback.
      return photo.path;
    }
  }

  /// Sinkronkan semua absensi tertunda secara FIFO. Berhenti saat menemui
  /// kegagalan jaringan (kemungkinan masih offline) agar urutan terjaga.
  ///
  /// Mengembalikan jumlah entri yang berhasil terkirim.
  Future<int> sync(AttendanceUploader uploader) async {
    if (_syncing) return 0;
    _syncing = true;
    var success = 0;
    try {
      final pending = await _db.getAll();
      for (final item in pending) {
        try {
          final ok = item.type == PendingAttendanceType.clockIn
              ? await uploader.uploadClockIn(item.toClockInRequest())
              : await uploader.uploadClockOut(item.toClockOutRequest());
          if (ok) {
            await _deleteWithPhoto(item);
            success++;
          } else {
            // Ditolak server (mis. sudah absen / validasi) — buang agar tidak
            // menyumbat antrean, tapi catat errornya.
            await _db.markFailed(item.id!, 'rejected_by_server');
            await _deleteWithPhoto(item);
          }
        } on SocketException {
          // Masih offline → hentikan, sisakan entri untuk percobaan berikutnya.
          break;
        } catch (e) {
          if (item.id != null) await _db.markFailed(item.id!, e.toString());
          break;
        }
      }
    } finally {
      _syncing = false;
      await refreshCount();
    }
    return success;
  }

  Future<void> _deleteWithPhoto(PendingAttendance item) async {
    if (item.id != null) await _db.delete(item.id!);
    final path = item.photoPath;
    if (path != null && path.contains('offline_attendance')) {
      final f = File(path);
      if (f.existsSync()) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
  }
}
