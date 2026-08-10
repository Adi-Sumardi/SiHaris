// RED test: ValidateGpsRequestModel
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/requests/validate_gps_request_model.dart';

void main() {
  group('ValidateGpsRequestModel', () {
    const tModel = ValidateGpsRequestModel(
      latitude: -6.2088,
      longitude: 106.8456,
    );

    test('should have correct latitude and longitude', () {
      expect(tModel.latitude, -6.2088);
      expect(tModel.longitude, 106.8456);
    });

    test('toJson() harus menghasilkan map dengan key yang benar', () {
      final json = tModel.toJson();
      expect(json['latitude'], -6.2088);
      expect(json['longitude'], 106.8456);
      expect(json.containsKey('latitude'), isTrue);
      expect(json.containsKey('longitude'), isTrue);
    });

    test('toJson() hanya berisi 2 key', () {
      final json = tModel.toJson();
      expect(json.length, 2);
    });

    test('dua model dengan nilai sama harus equal', () {
      const model2 = ValidateGpsRequestModel(
        latitude: -6.2088,
        longitude: 106.8456,
      );
      expect(tModel, model2);
    });

    test('dua model dengan nilai berbeda tidak equal', () {
      const model2 = ValidateGpsRequestModel(
        latitude: -7.0,
        longitude: 110.0,
      );
      expect(tModel, isNot(model2));
    });
  });
}
