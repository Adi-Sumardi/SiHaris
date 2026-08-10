import 'package:gaji_pro/data/models/requests/update_profile_request_model.dart';

abstract class UpdateProfileEvent {
  const UpdateProfileEvent();
}

class SubmitUpdateProfile extends UpdateProfileEvent {
  final UpdateProfileRequestModel request;
  const SubmitUpdateProfile(this.request);
}
