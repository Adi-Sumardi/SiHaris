import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/requests/clock_in_request_model.dart';

void main() {
  final tClockInRequestModel = ClockInRequestModel(
    latitude: -6.2088,
    longitude: 106.8456,
    notes: 'Late due to traffic',
    faceVerified: true,
    faceConfidence: 0.95,
    faceDescriptors: [0.1, 0.2, 0.3],
    gpsVerified: true,
    officeLocationId: 1,
    livenessPassed: true,
    // photo is File, hard to test equality directly, usually excluded from Equatable/== or handled separately
  );

  group('toJson', () {
    test('should return a JSON map containing proper data', () {
      // act
      final result = tClockInRequestModel.toJson();
      // assert
      final expectedMap = {
        "latitude": -6.2088,
        "longitude": 106.8456,
        "notes": "Late due to traffic",
        "face_verified": true,
        "face_confidence": 0.95,
        "face_descriptors": [0.1, 0.2, 0.3],
        "gps_verified": true,
        "office_location_id": 1,
        "liveness_passed": true,
      };
      // We don't verify photo in toJson because it's usually sent as multipart/form-data separately
      // checks for correctness
      expect(result, expectedMap);
    });
  });

  // Since request models usually don't need fromJson unless for debugging or internal use
  // We can skip fromJson test if not needed.
  // But define toMap/toJson is crucial for API requests.
}
