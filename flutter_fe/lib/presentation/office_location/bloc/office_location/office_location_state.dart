import 'package:gaji_pro/data/models/responses/office_location_model.dart';

abstract class OfficeLocationState {}

class OfficeLocationInitial extends OfficeLocationState {}

class OfficeLocationLoading extends OfficeLocationState {}

class OfficeLocationLoaded extends OfficeLocationState {
  final List<OfficeLocationModel> offices;

  OfficeLocationLoaded(this.offices);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfficeLocationLoaded &&
          runtimeType == other.runtimeType &&
          offices == other.offices;

  @override
  int get hashCode => offices.hashCode;
}

class OfficeLocationError extends OfficeLocationState {
  final String message;

  OfficeLocationError(this.message);
}
