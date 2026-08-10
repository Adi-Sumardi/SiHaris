abstract class GpsValidationEvent {
  const GpsValidationEvent();
}

class ValidateGpsLocation extends GpsValidationEvent {
  final double latitude;
  final double longitude;

  const ValidateGpsLocation({
    required this.latitude,
    required this.longitude,
  });
}

class ResetGpsValidation extends GpsValidationEvent {}
