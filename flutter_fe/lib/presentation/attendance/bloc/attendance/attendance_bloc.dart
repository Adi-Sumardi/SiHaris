import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/attendance_remote_datasource.dart';
import 'package:gaji_pro/data/models/requests/clock_in_request_model.dart';
import 'package:gaji_pro/data/models/requests/clock_out_request_model.dart';

part 'attendance_event.dart';
part 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRemoteDatasource datasource;

  AttendanceBloc({required this.datasource}) : super(AttendanceInitial()) {
    on<AttendanceClockIn>(_onClockIn);
    on<AttendanceClockOut>(_onClockOut);
  }

  Future<void> _onClockIn(
    AttendanceClockIn event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    final result = await datasource.clockIn(event.request);
    result.fold((failure) => emit(AttendanceFailure(failure)), (data) {
      final message = data['message'] ?? 'Clock in berhasil';
      emit(AttendanceSuccess(message));
    });
  }

  Future<void> _onClockOut(
    AttendanceClockOut event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    final result = await datasource.clockOut(event.request);
    result.fold((failure) => emit(AttendanceFailure(failure)), (data) {
      final message = data['message'] ?? 'Clock out berhasil';
      emit(AttendanceSuccess(message));
    });
  }
}
