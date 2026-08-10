import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/office_location_remote_datasource.dart';
import 'office_location_event.dart';
import 'office_location_state.dart';

class OfficeLocationBloc
    extends Bloc<OfficeLocationEvent, OfficeLocationState> {
  final OfficeLocationRemoteDatasource datasource;

  OfficeLocationBloc({required this.datasource})
      : super(OfficeLocationInitial()) {
    on<GetOfficeLocations>(_onGetOfficeLocations);
    on<GetAssignedOffices>(_onGetAssignedOffices);
  }

  Future<void> _onGetOfficeLocations(
    GetOfficeLocations event,
    Emitter<OfficeLocationState> emit,
  ) async {
    emit(OfficeLocationLoading());
    final result = await datasource.getOfficeLocations();
    result.fold(
      (failure) => emit(OfficeLocationError(failure)),
      (offices) => emit(OfficeLocationLoaded(offices)),
    );
  }

  Future<void> _onGetAssignedOffices(
    GetAssignedOffices event,
    Emitter<OfficeLocationState> emit,
  ) async {
    emit(OfficeLocationLoading());
    final result = await datasource.getAssignedOffices();
    result.fold(
      (failure) => emit(OfficeLocationError(failure)),
      (offices) => emit(OfficeLocationLoaded(offices)),
    );
  }
}
