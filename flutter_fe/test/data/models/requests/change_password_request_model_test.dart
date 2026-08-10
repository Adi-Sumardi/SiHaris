import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/requests/change_password_request_model.dart';

void main() {
  group('ChangePasswordRequestModel', () {
    test('should create instance with all fields', () {
      final model = ChangePasswordRequestModel(
        currentPassword: 'oldpass123',
        newPassword: 'newpass123',
        confirmPassword: 'newpass123',
      );

      expect(model.currentPassword, 'oldpass123');
      expect(model.newPassword, 'newpass123');
      expect(model.confirmPassword, 'newpass123');
    });

    test('toJson should return correct map', () {
      final model = ChangePasswordRequestModel(
        currentPassword: 'oldpass123',
        newPassword: 'newpass123',
        confirmPassword: 'newpass123',
      );

      final json = model.toJson();

      expect(json, {
        'current_password': 'oldpass123',
        'password': 'newpass123',
        'password_confirmation': 'newpass123',
      });
    });

    test('fromJson should create instance from map', () {
      final json = {
        'current_password': 'oldpass123',
        'password': 'newpass123',
        'password_confirmation': 'newpass123',
      };

      final model = ChangePasswordRequestModel.fromJson(json);

      expect(model.currentPassword, 'oldpass123');
      expect(model.newPassword, 'newpass123');
      expect(model.confirmPassword, 'newpass123');
    });

    test('copyWith should create new instance with updated values', () {
      final model = ChangePasswordRequestModel(
        currentPassword: 'oldpass123',
        newPassword: 'newpass123',
        confirmPassword: 'newpass123',
      );

      final updated = model.copyWith(newPassword: 'updated456');

      expect(updated.currentPassword, 'oldpass123');
      expect(updated.newPassword, 'updated456');
      expect(updated.confirmPassword, 'newpass123');
    });

    test('isValid should return true when all conditions met', () {
      final model = ChangePasswordRequestModel(
        currentPassword: 'oldpass123',
        newPassword: 'newpass123',
        confirmPassword: 'newpass123',
      );

      expect(model.isValid, true);
    });

    test('isValid should return false for empty current password', () {
      final model = ChangePasswordRequestModel(
        currentPassword: '',
        newPassword: 'newpass123',
        confirmPassword: 'newpass123',
      );

      expect(model.isValid, false);
    });

    test('isValid should return false for empty new password', () {
      final model = ChangePasswordRequestModel(
        currentPassword: 'oldpass123',
        newPassword: '',
        confirmPassword: '',
      );

      expect(model.isValid, false);
    });

    test('isValid should return false when passwords do not match', () {
      final model = ChangePasswordRequestModel(
        currentPassword: 'oldpass123',
        newPassword: 'newpass123',
        confirmPassword: 'different456',
      );

      expect(model.isValid, false);
    });

    test('isValid should return false when new password is too short', () {
      final model = ChangePasswordRequestModel(
        currentPassword: 'oldpass123',
        newPassword: '12345',
        confirmPassword: '12345',
      );

      expect(model.isValid, false);
    });

    test('isValid should return false when new password equals current', () {
      final model = ChangePasswordRequestModel(
        currentPassword: 'samepass123',
        newPassword: 'samepass123',
        confirmPassword: 'samepass123',
      );

      expect(model.isValid, false);
    });

    test('passwordsMatch should return true when passwords match', () {
      final model = ChangePasswordRequestModel(
        currentPassword: 'oldpass123',
        newPassword: 'newpass123',
        confirmPassword: 'newpass123',
      );

      expect(model.passwordsMatch, true);
    });

    test('passwordsMatch should return false when passwords differ', () {
      final model = ChangePasswordRequestModel(
        currentPassword: 'oldpass123',
        newPassword: 'newpass123',
        confirmPassword: 'different456',
      );

      expect(model.passwordsMatch, false);
    });

    test('equality should work correctly', () {
      final model1 = ChangePasswordRequestModel(
        currentPassword: 'oldpass123',
        newPassword: 'newpass123',
        confirmPassword: 'newpass123',
      );
      final model2 = ChangePasswordRequestModel(
        currentPassword: 'oldpass123',
        newPassword: 'newpass123',
        confirmPassword: 'newpass123',
      );

      expect(model1, equals(model2));
    });

    test('validate should return null for valid data', () {
      final model = ChangePasswordRequestModel(
        currentPassword: 'oldpass123',
        newPassword: 'newpass123',
        confirmPassword: 'newpass123',
      );

      expect(model.validate(), isNull);
    });

    test('validate should return error for empty current password', () {
      final model = ChangePasswordRequestModel(
        currentPassword: '',
        newPassword: 'newpass123',
        confirmPassword: 'newpass123',
      );

      expect(model.validate(), isNotNull);
      expect(model.validate(), contains('Password saat ini'));
    });

    test('validate should return error for short new password', () {
      final model = ChangePasswordRequestModel(
        currentPassword: 'oldpass123',
        newPassword: '12345',
        confirmPassword: '12345',
      );

      expect(model.validate(), isNotNull);
      expect(model.validate(), contains('minimal'));
    });

    test('validate should return error for mismatched passwords', () {
      final model = ChangePasswordRequestModel(
        currentPassword: 'oldpass123',
        newPassword: 'newpass123',
        confirmPassword: 'different456',
      );

      expect(model.validate(), isNotNull);
      expect(model.validate(), contains('tidak cocok'));
    });

    test('validate should return error when new equals current', () {
      final model = ChangePasswordRequestModel(
        currentPassword: 'samepass123',
        newPassword: 'samepass123',
        confirmPassword: 'samepass123',
      );

      expect(model.validate(), isNotNull);
      expect(model.validate(), contains('berbeda'));
    });
  });
}
