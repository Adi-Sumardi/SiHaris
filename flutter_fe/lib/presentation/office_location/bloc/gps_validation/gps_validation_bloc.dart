import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/office_location_remote_datasource.dart';
import 'package:gaji_pro/data/models/requests/validate_gps_request_model.dart';
import 'gps_validation_event.dart';
import 'gps_validation_state.dart';

class GpsValidationBloc extends Bloc<GpsValidationEvent, GpsValidationState> {
  final OfficeLocationRemoteDatasource datasource;

  GpsValidationBloc({required this.datasource}) : super(GpsValidationInitial()) {
    on<ValidateGpsLocation>(_onValidateGpsLocation);
    on<ResetGpsValidation>(_onResetGpsValidation);
  }

  Future<void> _onValidateGpsLocation(
    ValidateGpsLocation event,
    Emitter<GpsValidationState> emit,
  ) async {
    emit(GpsValidationLoading());
    final result = await datasource.validateGps(
      ValidateGpsRequestModel(
        latitude: event.latitude,
        longitude: event.longitude,
      ),
    );
    result.fold(
      (failure) => emit(GpsValidationFailure(failure)),
      (response) => emit(GpsValidationSuccess(response)),
    );
  }

  void _onResetGpsValidation(
    ResetGpsValidation event,
    Emitter<GpsValidationState> emit,
  ) {
    emit(GpsValidationInitial());
  }
}
