import 'package:gaji_pro/data/models/requests/face_recognition/face_enroll_request_model.dart';

abstract class FaceEnrollEvent {}

class SubmitFaceEnroll extends FaceEnrollEvent {
  final FaceEnrollRequestModel request;
  SubmitFaceEnroll({required this.request});
}

class ResetFaceEnroll extends FaceEnrollEvent {}
