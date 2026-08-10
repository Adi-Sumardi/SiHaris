import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/responses/device_token_model.dart';

void main() {
  final tDeviceTokenModel = DeviceTokenModel(
    id: 1,
    platform: 'android',
    deviceName: 'Test Device',
    deviceModel: 'Pixel 4',
    appVersion: '1.0.0',
    isActive: true,
    lastUsedAt: DateTime.parse('2024-02-17T10:00:00Z'),
  );

  group('DeviceTokenModel', () {
    test('should return a valid model from JSON', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {
        'id': 1,
        'platform': 'android',
        'device_name': 'Test Device',
        'device_model': 'Pixel 4',
        'app_version': '1.0.0',
        'is_active': true,
        'last_used_at': '2024-02-17T10:00:00Z',
      };

      // Act
      final result = DeviceTokenModel.fromJson(jsonMap);

      // Assert
      expect(result, tDeviceTokenModel);
    });

    test('should handle null optional fields', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {
        'id': 2,
        'platform': 'ios',
        'is_active': false,
        'last_used_at': null,
      };

      // Act
      final result = DeviceTokenModel.fromJson(jsonMap);

      // Assert
      expect(result.id, 2);
      expect(result.platform, 'ios');
      expect(result.deviceName, null);
      expect(result.deviceModel, null);
      expect(result.appVersion, null);
      expect(result.isActive, false);
      expect(result.lastUsedAt, null);
    });

    test('props should contain all fields', () {
      expect(tDeviceTokenModel.props, [
        1,
        'android',
        'Test Device',
        'Pixel 4',
        '1.0.0',
        true,
        DateTime.parse('2024-02-17T10:00:00Z'),
      ]);
    });

    test('should handle partial optional fields', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {
        'id': 3,
        'platform': 'android',
        'device_name': 'Samsung',
        'device_model': 'Galaxy S21',
        'is_active': true,
      };

      // Act
      final result = DeviceTokenModel.fromJson(jsonMap);

      // Assert
      expect(result.id, 3);
      expect(result.platform, 'android');
      expect(result.deviceName, 'Samsung');
      expect(result.deviceModel, 'Galaxy S21');
      expect(result.appVersion, null);
      expect(result.isActive, true);
      expect(result.lastUsedAt, null);
    });
  });
}
