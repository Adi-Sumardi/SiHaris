import 'package:gaji_pro/data/models/responses/face_recognition/face_recognition_status_model.dart';

abstract class FaceEnrollState {}

class FaceEnrollInitial extends FaceEnrollState {}

class FaceEnrollLoading extends FaceEnrollState {}

class FaceEnrollSuccess extends FaceEnrollState {
  final FaceEnrollResponseModel response;
  FaceEnrollSuccess({required this.response});
}

class FaceEnrollError extends FaceEnrollState {
  final String message;
  FaceEnrollError(this.message);
}
