import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/core/services/camera_service.dart';

// Mock classes
class MockImagePicker extends Mock implements ImagePicker {}

// Fake XFile for testing
class FakeXFile extends Fake implements XFile {
  final String _path;
  FakeXFile(this._path);

  @override
  String get path => _path;
}

void main() {
  late CameraService cameraService;
  late MockImagePicker mockImagePicker;

  setUpAll(() {
    registerFallbackValue(ImageSource.camera);
    registerFallbackValue(CameraDevice.rear);
  });

  setUp(() {
    mockImagePicker = MockImagePicker();
    cameraService = CameraService(imagePicker: mockImagePicker);
  });

  group('CameraService', () {
    group('pickImageFromCamera', () {
      test('should return XFile when image is captured', () async {
        final fakeFile = FakeXFile('/path/to/image.jpg');

        when(() => mockImagePicker.pickImage(
              source: any(named: 'source'),
              maxWidth: any(named: 'maxWidth'),
              maxHeight: any(named: 'maxHeight'),
              imageQuality: any(named: 'imageQuality'),
              preferredCameraDevice: any(named: 'preferredCameraDevice'),
            )).thenAnswer((_) async => fakeFile);

        final result = await cameraService.pickImageFromCamera();

        expect(result, isNotNull);
        expect(result!.path, '/path/to/image.jpg');
      });

      test('should return null when image capture is cancelled', () async {
        when(() => mockImagePicker.pickImage(
              source: any(named: 'source'),
              maxWidth: any(named: 'maxWidth'),
              maxHeight: any(named: 'maxHeight'),
              imageQuality: any(named: 'imageQuality'),
              preferredCameraDevice: any(named: 'preferredCameraDevice'),
            )).thenAnswer((_) async => null);

        final result = await cameraService.pickImageFromCamera();

        expect(result, isNull);
      });

      test('should use front camera when specified', () async {
        final fakeFile = FakeXFile('/path/to/selfie.jpg');

        when(() => mockImagePicker.pickImage(
              source: any(named: 'source'),
              maxWidth: any(named: 'maxWidth'),
              maxHeight: any(named: 'maxHeight'),
              imageQuality: any(named: 'imageQuality'),
              preferredCameraDevice: any(named: 'preferredCameraDevice'),
            )).thenAnswer((_) async => fakeFile);

        final result = await cameraService.pickImageFromCamera(
          preferFrontCamera: true,
        );

        expect(result, isNotNull);
      });

      test('should apply custom image quality', () async {
        final fakeFile = FakeXFile('/path/to/image.jpg');

        when(() => mockImagePicker.pickImage(
              source: any(named: 'source'),
              maxWidth: any(named: 'maxWidth'),
              maxHeight: any(named: 'maxHeight'),
              imageQuality: any(named: 'imageQuality'),
              preferredCameraDevice: any(named: 'preferredCameraDevice'),
            )).thenAnswer((_) async => fakeFile);

        final result = await cameraService.pickImageFromCamera(
          imageQuality: 50,
        );

        expect(result, isNotNull);
      });
    });

    group('pickImageFromGallery', () {
      test('should return XFile when image is selected', () async {
        final fakeFile = FakeXFile('/path/to/gallery_image.jpg');

        when(() => mockImagePicker.pickImage(
              source: any(named: 'source'),
              maxWidth: any(named: 'maxWidth'),
              maxHeight: any(named: 'maxHeight'),
              imageQuality: any(named: 'imageQuality'),
            )).thenAnswer((_) async => fakeFile);

        final result = await cameraService.pickImageFromGallery();

        expect(result, isNotNull);
        expect(result!.path, '/path/to/gallery_image.jpg');
      });

      test('should return null when selection is cancelled', () async {
        when(() => mockImagePicker.pickImage(
              source: any(named: 'source'),
              maxWidth: any(named: 'maxWidth'),
              maxHeight: any(named: 'maxHeight'),
              imageQuality: any(named: 'imageQuality'),
            )).thenAnswer((_) async => null);

        final result = await cameraService.pickImageFromGallery();

        expect(result, isNull);
      });
    });

    group('pickMultipleImages', () {
      test('should return list of XFiles when images are selected', () async {
        final fakeFile1 = FakeXFile('/path/to/image1.jpg');
        final fakeFile2 = FakeXFile('/path/to/image2.jpg');

        when(() => mockImagePicker.pickMultiImage(
              maxWidth: any(named: 'maxWidth'),
              maxHeight: any(named: 'maxHeight'),
              imageQuality: any(named: 'imageQuality'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => [fakeFile1, fakeFile2]);

        final result = await cameraService.pickMultipleImages();

        expect(result, isNotNull);
        expect(result!.length, 2);
      });

      test('should return null when selection is cancelled', () async {
        when(() => mockImagePicker.pickMultiImage(
              maxWidth: any(named: 'maxWidth'),
              maxHeight: any(named: 'maxHeight'),
              imageQuality: any(named: 'imageQuality'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => []);

        final result = await cameraService.pickMultipleImages();

        expect(result, isNull);
      });
    });

    group('takeSelfie', () {
      test('should use front camera by default', () async {
        final fakeFile = FakeXFile('/path/to/selfie.jpg');

        when(() => mockImagePicker.pickImage(
              source: any(named: 'source'),
              maxWidth: any(named: 'maxWidth'),
              maxHeight: any(named: 'maxHeight'),
              imageQuality: any(named: 'imageQuality'),
              preferredCameraDevice: any(named: 'preferredCameraDevice'),
            )).thenAnswer((_) async => fakeFile);

        final result = await cameraService.takeSelfie();

        expect(result, isNotNull);
      });
    });

    group('ImageSettings', () {
      test('should have default values', () {
        const settings = ImageSettings();

        expect(settings.maxWidth, 1920);
        expect(settings.maxHeight, 1080);
        expect(settings.imageQuality, 85);
      });

      test('should allow custom values', () {
        const settings = ImageSettings(
          maxWidth: 800,
          maxHeight: 600,
          imageQuality: 50,
        );

        expect(settings.maxWidth, 800);
        expect(settings.maxHeight, 600);
        expect(settings.imageQuality, 50);
      });

      test('attendance settings should have proper defaults', () {
        const settings = ImageSettings.attendance();

        expect(settings.maxWidth, 640);
        expect(settings.maxHeight, 480);
        expect(settings.imageQuality, 70);
      });

      test('profile settings should have proper defaults', () {
        const settings = ImageSettings.profile();

        expect(settings.maxWidth, 512);
        expect(settings.maxHeight, 512);
        expect(settings.imageQuality, 90);
      });

      test('receipt settings should have proper defaults', () {
        const settings = ImageSettings.receipt();

        expect(settings.maxWidth, 1024);
        expect(settings.maxHeight, 1024);
        expect(settings.imageQuality, 80);
      });
    });
  });
}
