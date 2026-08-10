// RED test: UpdateProfileRequestModel
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/requests/update_profile_request_model.dart';

void main() {
  group('UpdateProfileRequestModel', () {
    test('toFields() menghasilkan map hanya dari field yang tidak null', () {
      final model = UpdateProfileRequestModel(
        firstName: 'Ahmad',
        lastName: 'Bahri',
        phone: '08123456789',
      );

      final fields = model.toFields();

      expect(fields['first_name'], 'Ahmad');
      expect(fields['last_name'], 'Bahri');
      expect(fields['phone'], '08123456789');
      expect(fields.containsKey('photo'), isFalse);
    });

    test('toFields() skip field yang null', () {
      final model = UpdateProfileRequestModel(
        firstName: 'Ahmad',
      );

      final fields = model.toFields();

      expect(fields['first_name'], 'Ahmad');
      expect(fields.containsKey('last_name'), isFalse);
      expect(fields.containsKey('phone'), isFalse);
    });

    test('toFields() menghasilkan map kosong jika semua field null', () {
      final model = UpdateProfileRequestModel();

      final fields = model.toFields();

      expect(fields.isEmpty, isTrue);
    });

    test('hasPhoto returns true jika photo tidak null', () {
      final model = UpdateProfileRequestModel(
        photo: File('/tmp/avatar.jpg'),
      );

      expect(model.hasPhoto, isTrue);
    });

    test('hasPhoto returns false jika photo null', () {
      final model = UpdateProfileRequestModel(firstName: 'Ahmad');

      expect(model.hasPhoto, isFalse);
    });
  });
}
