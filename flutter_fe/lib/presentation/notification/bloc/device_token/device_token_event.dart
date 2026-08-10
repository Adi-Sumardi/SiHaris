import 'package:equatable/equatable.dart';
import '../../../../data/models/requests/register_token_request_model.dart';

abstract class DeviceTokenEvent extends Equatable {
  const DeviceTokenEvent();

  @override
  List<Object?> get props => [];
}

class RegisterDeviceToken extends DeviceTokenEvent {
  final RegisterTokenRequestModel request;

  const RegisterDeviceToken(this.request);

  @override
  List<Object?> get props => [request];
}

class UnregisterDeviceToken extends DeviceTokenEvent {
  final String token;

  const UnregisterDeviceToken(this.token);

  @override
  List<Object?> get props => [token];
}

class RefreshDeviceToken extends DeviceTokenEvent {
  final String oldToken;
  final String newToken;

  const RefreshDeviceToken({required this.oldToken, required this.newToken});

  @override
  List<Object?> get props => [oldToken, newToken];
}

class LoadDeviceTokens extends DeviceTokenEvent {}
