import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/requests/login_request_model.dart';

void main() {
  group('LoginRequestModel', () {
    test('should create instance with email and password', () {
      final model = LoginRequestModel(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(model.email, 'test@example.com');
      expect(model.password, 'password123');
    });

    test('toJson should return correct map', () {
      final model = LoginRequestModel(
        email: 'test@example.com',
        password: 'password123',
      );

      final json = model.toJson();

      expect(json, {
        'email': 'test@example.com',
        'password': 'password123',
      });
    });

    test('fromJson should create instance from map', () {
      final json = {
        'email': 'test@example.com',
        'password': 'password123',
      };

      final model = LoginRequestModel.fromJson(json);

      expect(model.email, 'test@example.com');
      expect(model.password, 'password123');
    });

    test('copyWith should create new instance with updated values', () {
      final model = LoginRequestModel(
        email: 'test@example.com',
        password: 'password123',
      );

      final updated = model.copyWith(email: 'new@example.com');

      expect(updated.email, 'new@example.com');
      expect(updated.password, 'password123');
      expect(model.email, 'test@example.com'); // original unchanged
    });

    test('copyWith should keep original values when not specified', () {
      final model = LoginRequestModel(
        email: 'test@example.com',
        password: 'password123',
      );

      final updated = model.copyWith();

      expect(updated.email, 'test@example.com');
      expect(updated.password, 'password123');
    });

    test('equality should work correctly', () {
      final model1 = LoginRequestModel(
        email: 'test@example.com',
        password: 'password123',
      );
      final model2 = LoginRequestModel(
        email: 'test@example.com',
        password: 'password123',
      );
      final model3 = LoginRequestModel(
        email: 'different@example.com',
        password: 'password123',
      );

      expect(model1, equals(model2));
      expect(model1, isNot(equals(model3)));
    });

    test('hashCode should be consistent with equality', () {
      final model1 = LoginRequestModel(
        email: 'test@example.com',
        password: 'password123',
      );
      final model2 = LoginRequestModel(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(model1.hashCode, equals(model2.hashCode));
    });

    test('toString should return readable string', () {
      final model = LoginRequestModel(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(model.toString(), contains('test@example.com'));
      expect(model.toString(), contains('LoginRequestModel'));
    });

    test('isValid should return true for valid data', () {
      final model = LoginRequestModel(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(model.isValid, true);
    });

    test('isValid should return false for empty email', () {
      final model = LoginRequestModel(
        email: '',
        password: 'password123',
      );

      expect(model.isValid, false);
    });

    test('isValid should return false for empty password', () {
      final model = LoginRequestModel(
        email: 'test@example.com',
        password: '',
      );

      expect(model.isValid, false);
    });

    test('isValid should return false for invalid email format', () {
      final model = LoginRequestModel(
        email: 'invalid-email',
        password: 'password123',
      );

      expect(model.isValid, false);
    });
  });
}
