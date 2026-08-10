import 'package:gaji_pro/data/models/responses/face_recognition/face_recognition_status_model.dart';

abstract class FaceRecognitionStatusState {}

class FaceRecognitionStatusInitial extends FaceRecognitionStatusState {}

class FaceRecognitionStatusLoading extends FaceRecognitionStatusState {}

class FaceRecognitionStatusLoaded extends FaceRecognitionStatusState {
  final FaceRecognitionStatusModel status;
  FaceRecognitionStatusLoaded(this.status);
}

class FaceRecognitionStatusError extends FaceRecognitionStatusState {
  final String message;
  FaceRecognitionStatusError(this.message);
}
