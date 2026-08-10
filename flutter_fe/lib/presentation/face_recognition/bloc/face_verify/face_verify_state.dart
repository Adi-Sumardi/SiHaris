import 'package:gaji_pro/data/models/responses/face_recognition/face_recognition_status_model.dart';

abstract class FaceVerifyState {}

class FaceVerifyInitial extends FaceVerifyState {}

class FaceVerifyLoading extends FaceVerifyState {}

class FaceVerifyMatched extends FaceVerifyState {
  final FaceVerifyResponseModel response;
  FaceVerifyMatched({required this.response});
}

class FaceVerifyNotMatched extends FaceVerifyState {
  final FaceVerifyResponseModel response;
  FaceVerifyNotMatched({required this.response});
}

class FaceVerifyError extends FaceVerifyState {
  final String message;
  FaceVerifyError(this.message);
}
