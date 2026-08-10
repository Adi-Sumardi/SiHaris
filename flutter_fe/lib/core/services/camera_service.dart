import 'package:image_picker/image_picker.dart';

/// Service for handling camera and gallery image picking
class CameraService {
  final ImagePicker _imagePicker;

  CameraService({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  /// Pick an image from camera
  /// Returns null if cancelled
  Future<XFile?> pickImageFromCamera({
    bool preferFrontCamera = false,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      return await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth?.toDouble() ?? 1920,
        maxHeight: maxHeight?.toDouble() ?? 1080,
        imageQuality: imageQuality ?? 85,
        preferredCameraDevice:
            preferFrontCamera ? CameraDevice.front : CameraDevice.rear,
      );
    } catch (e) {
      return null;
    }
  }

  /// Pick an image from gallery
  /// Returns null if cancelled
  Future<XFile?> pickImageFromGallery({
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      return await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth?.toDouble() ?? 1920,
        maxHeight: maxHeight?.toDouble() ?? 1080,
        imageQuality: imageQuality ?? 85,
      );
    } catch (e) {
      return null;
    }
  }

  /// Pick multiple images from gallery
  /// Returns null if cancelled or empty selection
  Future<List<XFile>?> pickMultipleImages({
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
    int? limit,
  }) async {
    try {
      final images = await _imagePicker.pickMultiImage(
        maxWidth: maxWidth?.toDouble() ?? 1920,
        maxHeight: maxHeight?.toDouble() ?? 1080,
        imageQuality: imageQuality ?? 85,
        limit: limit,
      );
      if (images.isEmpty) return null;
      return images;
    } catch (e) {
      return null;
    }
  }

  /// Take a selfie (uses front camera by default)
  Future<XFile?> takeSelfie({
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    return pickImageFromCamera(
      preferFrontCamera: true,
      maxWidth: maxWidth ?? 640,
      maxHeight: maxHeight ?? 480,
      imageQuality: imageQuality ?? 70,
    );
  }

  /// Take a photo for attendance (optimized settings)
  Future<XFile?> takeAttendancePhoto() async {
    const settings = ImageSettings.attendance();
    return pickImageFromCamera(
      preferFrontCamera: true,
      maxWidth: settings.maxWidth.toInt(),
      maxHeight: settings.maxHeight.toInt(),
      imageQuality: settings.imageQuality,
    );
  }

  /// Pick a receipt image
  Future<XFile?> pickReceiptImage({bool fromCamera = false}) async {
    const settings = ImageSettings.receipt();
    if (fromCamera) {
      return pickImageFromCamera(
        maxWidth: settings.maxWidth.toInt(),
        maxHeight: settings.maxHeight.toInt(),
        imageQuality: settings.imageQuality,
      );
    }
    return pickImageFromGallery(
      maxWidth: settings.maxWidth.toInt(),
      maxHeight: settings.maxHeight.toInt(),
      imageQuality: settings.imageQuality,
    );
  }

  /// Pick a profile image
  Future<XFile?> pickProfileImage({bool fromCamera = false}) async {
    const settings = ImageSettings.profile();
    if (fromCamera) {
      return pickImageFromCamera(
        preferFrontCamera: true,
        maxWidth: settings.maxWidth.toInt(),
        maxHeight: settings.maxHeight.toInt(),
        imageQuality: settings.imageQuality,
      );
    }
    return pickImageFromGallery(
      maxWidth: settings.maxWidth.toInt(),
      maxHeight: settings.maxHeight.toInt(),
      imageQuality: settings.imageQuality,
    );
  }
}

/// Image settings configuration
class ImageSettings {
  final double maxWidth;
  final double maxHeight;
  final int imageQuality;

  const ImageSettings({
    this.maxWidth = 1920,
    this.maxHeight = 1080,
    this.imageQuality = 85,
  });

  /// Settings for attendance photos (smaller, optimized)
  const ImageSettings.attendance()
      : maxWidth = 640,
        maxHeight = 480,
        imageQuality = 70;

  /// Settings for profile photos (square, high quality)
  const ImageSettings.profile()
      : maxWidth = 512,
        maxHeight = 512,
        imageQuality = 90;

  /// Settings for receipt/document photos (medium, good quality)
  const ImageSettings.receipt()
      : maxWidth = 1024,
        maxHeight = 1024,
        imageQuality = 80;

  /// Settings for full resolution photos
  const ImageSettings.fullResolution()
      : maxWidth = 3840,
        maxHeight = 2160,
        imageQuality = 95;
}
