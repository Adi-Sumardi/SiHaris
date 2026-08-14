import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/requests/clock_out_request_model.dart';

void main() {
  final tClockOutRequestModel = ClockOutRequestModel(
    latitude: -6.2088,
    longitude: 106.8456,
    notes: 'Leaving early',
    faceVerified: true,
    faceConfidence: 0.98,
    faceDescriptors: [0.1, 0.2, 0.3],
    gpsVerified: true,
    officeLocationId: 1,
    livenessPassed: true,
  );

  group('toJson', () {
    test('should return a JSON map containing proper data', () {
      // act
      final result = tClockOutRequestModel.toJson();
      // assert
      final expectedMap = {
        "latitude": -6.2088,
        "longitude": 106.8456,
        "notes": "Leaving early",
        "face_verified": true,
        "face_confidence": 0.98,
        "face_descriptors": [0.1, 0.2, 0.3],
        "gps_verified": true,
        "office_location_id": 1,
        "liveness_passed": true,
      };
      expect(result, expectedMap);
    });
  });
}
