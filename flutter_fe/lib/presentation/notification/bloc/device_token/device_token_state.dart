import 'package:equatable/equatable.dart';
import '../../../../data/models/responses/device_token_model.dart';

abstract class DeviceTokenState extends Equatable {
  const DeviceTokenState();

  @override
  List<Object?> get props => [];
}

class DeviceTokenInitial extends DeviceTokenState {}

class DeviceTokenLoading extends DeviceTokenState {}

class DeviceTokenSuccess extends DeviceTokenState {
  final String message;

  const DeviceTokenSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class DeviceTokenListLoaded extends DeviceTokenState {
  final List<DeviceTokenModel> tokens;

  const DeviceTokenListLoaded(this.tokens);

  @override
  List<Object?> get props => [tokens];
}

class DeviceTokenFailure extends DeviceTokenState {
  final String message;

  const DeviceTokenFailure(this.message);

  @override
  List<Object?> get props => [message];
}
