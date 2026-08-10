import 'dart:io';

import '../../../data/models/requests/clock_in_request_model.dart';
import '../../../data/models/requests/clock_out_request_model.dart';

/// Jenis absensi yang diantrekan saat offline.
enum PendingAttendanceType { clockIn, clockOut }

/// Satu entri absensi yang tersimpan lokal karena dilakukan saat offline,
/// menunggu disinkronkan ke server.
class PendingAttendance {
  final int? id;
  final PendingAttendanceType type;
  final double latitude;
  final double longitude;
  final int officeLocationId;
  final bool gpsVerified;
  final bool faceVerified;
  final double? faceConfidence;
  final String? notes;
  final String? photoPath;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  PendingAttendance({
    this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.officeLocationId,
    required this.gpsVerified,
    required this.faceVerified,
    this.faceConfidence,
    this.notes,
    this.photoPath,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'type': type == PendingAttendanceType.clockIn ? 'clock_in' : 'clock_out',
        'latitude': latitude,
        'longitude': longitude,
        'office_location_id': officeLocationId,
        'gps_verified': gpsVerified ? 1 : 0,
        'face_verified': faceVerified ? 1 : 0,
        'face_confidence': faceConfidence,
        'notes': notes,
        'photo_path': photoPath,
        'created_at': createdAt.toIso8601String(),
        'retry_count': retryCount,
        'last_error': lastError,
      };

  factory PendingAttendance.fromMap(Map<String, Object?> map) {
    return PendingAttendance(
      id: map['id'] as int?,
      type: (map['type'] as String?) == 'clock_out'
          ? PendingAttendanceType.clockOut
          : PendingAttendanceType.clockIn,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      officeLocationId: (map['office_location_id'] as num).toInt(),
      gpsVerified: (map['gps_verified'] as num? ?? 0) == 1,
      faceVerified: (map['face_verified'] as num? ?? 0) == 1,
      faceConfidence: (map['face_confidence'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      photoPath: map['photo_path'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      retryCount: (map['retry_count'] as num? ?? 0).toInt(),
      lastError: map['last_error'] as String?,
    );
  }

  /// File foto absensi (jika ada & masih tersimpan di disk).
  File? get photoFile {
    final path = photoPath;
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  ClockInRequestModel toClockInRequest() => ClockInRequestModel(
        latitude: latitude,
        longitude: longitude,
        photo: photoFile,
        notes: notes,
        faceVerified: faceVerified,
        faceConfidence: faceConfidence,
        gpsVerified: gpsVerified,
        officeLocationId: officeLocationId,
      );

  ClockOutRequestModel toClockOutRequest() => ClockOutRequestModel(
        latitude: latitude,
        longitude: longitude,
        photo: photoFile,
        notes: notes,
        faceVerified: faceVerified,
        faceConfidence: faceConfidence,
        gpsVerified: gpsVerified,
        officeLocationId: officeLocationId,
      );
}
