import 'package:gaji_pro/data/models/requests/face_recognition/face_verify_request_model.dart';

abstract class FaceVerifyEvent {}

class VerifyFace extends FaceVerifyEvent {
  final FaceVerifyRequestModel request;
  VerifyFace({required this.request});
}

class ResetFaceVerify extends FaceVerifyEvent {}
