import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/requests/face_recognition/face_verify_request_model.dart';

void main() {
  final testDescriptors = List.generate(192, (i) => i * 0.01);

  group('FaceVerifyRequestModel', () {
    test('toJson() menghasilkan descriptors sebagai list', () {
      final model = FaceVerifyRequestModel(
        descriptors: testDescriptors,
        verificationType: VerificationType.clockIn,
      );
      final json = model.toJson();

      expect(json['descriptors'], isA<List>());
      expect(json['descriptors'].length, 192);
    });

    test('toJson() dengan verificationType clockIn menghasilkan "clock_in"', () {
      final model = FaceVerifyRequestModel(
        descriptors: testDescriptors,
        verificationType: VerificationType.clockIn,
      );
      final json = model.toJson();

      expect(json['verification_type'], 'clock_in');
    });

    test('toJson() dengan verificationType clockOut menghasilkan "clock_out"', () {
      final model = FaceVerifyRequestModel(
        descriptors: testDescriptors,
        verificationType: VerificationType.clockOut,
      );
      final json = model.toJson();

      expect(json['verification_type'], 'clock_out');
    });

    test('toJson() tanpa verificationType tidak menambah field', () {
      final model = FaceVerifyRequestModel(descriptors: testDescriptors);
      final json = model.toJson();

      expect(json.containsKey('verification_type'), isFalse);
    });

    test('descriptors harus tersimpan dengan benar', () {
      final model = FaceVerifyRequestModel(descriptors: testDescriptors);
      expect(model.descriptors.length, 192);
      expect(model.descriptors[0], closeTo(0.0, 0.001));
    });
  });
}
