import 'dart:io';

class ClockOutRequestModel {
  final double latitude;
  final double longitude;
  final File? photo;
  final String? notes;
  final bool faceVerified;
  final bool livenessPassed;
  final double? faceConfidence;
  final List<double>? faceDescriptors;
  final bool gpsVerified;
  final int officeLocationId;

  ClockOutRequestModel({
    required this.latitude,
    required this.longitude,
    this.photo,
    this.notes,
    this.faceVerified = false,
    this.livenessPassed = true,
    this.faceConfidence,
    this.faceDescriptors,
    this.gpsVerified = false,
    required this.officeLocationId,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
      'face_verified': faceVerified,
      'liveness_passed': livenessPassed,
      'face_confidence': faceConfidence,
      'face_descriptors': faceDescriptors,
      'gps_verified': gpsVerified,
      'office_location_id': officeLocationId,
    };
  }
}
