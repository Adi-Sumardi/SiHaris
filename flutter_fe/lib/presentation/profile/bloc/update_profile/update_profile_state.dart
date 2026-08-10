import 'package:gaji_pro/data/models/responses/auth_response_model.dart';

abstract class UpdateProfileState {
  const UpdateProfileState();
}

class UpdateProfileInitial extends UpdateProfileState {
  @override
  bool operator ==(Object other) => other is UpdateProfileInitial;
  @override
  int get hashCode => runtimeType.hashCode;
}

class UpdateProfileLoading extends UpdateProfileState {
  @override
  bool operator ==(Object other) => other is UpdateProfileLoading;
  @override
  int get hashCode => runtimeType.hashCode;
}

class UpdateProfileSuccess extends UpdateProfileState {
  final UserModel user;
  const UpdateProfileSuccess(this.user);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateProfileSuccess && other.user == user;
  @override
  int get hashCode => user.hashCode;
}

class UpdateProfileFailure extends UpdateProfileState {
  final String message;
  const UpdateProfileFailure(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateProfileFailure && other.message == message;
  @override
  int get hashCode => message.hashCode;
}
