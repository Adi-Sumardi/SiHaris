import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/requests/register_token_request_model.dart';

void main() {
  const tRegisterTokenRequestModel = RegisterTokenRequestModel(
    token: 'test_token',
    platform: 'android',
    deviceName: 'Test Device',
    deviceModel: 'Pixel 4',
    appVersion: '1.0.0',
  );

  group('RegisterTokenRequestModel', () {
    test('should return a valid JSON map', () {
      // Act
      final result = tRegisterTokenRequestModel.toJson();

      // Assert
      expect(result, {
        'token': 'test_token',
        'platform': 'android',
        'device_name': 'Test Device',
        'device_model': 'Pixel 4',
        'app_version': '1.0.0',
      });
    });

    test('should exclude null fields from JSON', () {
      // Arrange
      const model = RegisterTokenRequestModel(
        token: 'test_token',
        platform: 'ios',
      );

      // Act
      final result = model.toJson();

      // Assert
      expect(result, {'token': 'test_token', 'platform': 'ios'});
    });

    test('props should contain all fields', () {
      expect(tRegisterTokenRequestModel.props, [
        'test_token',
        'android',
        'Test Device',
        'Pixel 4',
        '1.0.0',
      ]);
    });
  });
}
