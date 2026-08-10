import '../../../../data/models/responses/auth_response_model.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserModel user;
  final CompanyModel? company;

  ProfileLoaded(this.user, {this.company});
}

class ProfileError extends ProfileState {
  final String message;

  ProfileError(this.message);
}
