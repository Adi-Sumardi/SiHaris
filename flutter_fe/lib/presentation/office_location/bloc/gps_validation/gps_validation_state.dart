import 'package:gaji_pro/data/models/responses/office_location_model.dart';

abstract class GpsValidationState {}

class GpsValidationInitial extends GpsValidationState {}

class GpsValidationLoading extends GpsValidationState {}

class GpsValidationSuccess extends GpsValidationState {
  final GpsValidationResponse response;

  GpsValidationSuccess(this.response);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GpsValidationSuccess &&
          runtimeType == other.runtimeType &&
          response == other.response;

  @override
  int get hashCode => response.hashCode;
}

class GpsValidationFailure extends GpsValidationState {
  final String message;

  GpsValidationFailure(this.message);
}
