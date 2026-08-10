import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/attendance_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/attendance_today_model.dart';

part 'attendance_today_event.dart';
part 'attendance_today_state.dart';

class AttendanceTodayBloc
    extends Bloc<AttendanceTodayEvent, AttendanceTodayState> {
  final AttendanceRemoteDatasource datasource;

  AttendanceTodayBloc({required this.datasource})
    : super(AttendanceTodayInitial()) {
    on<GetTodayStatus>(_onGetTodayStatus);
  }

  Future<void> _onGetTodayStatus(
    GetTodayStatus event,
    Emitter<AttendanceTodayState> emit,
  ) async {
    emit(AttendanceTodayLoading());
    final result = await datasource.getTodayAttendance();
    result.fold(
      (failure) {
        if (failure.toLowerCase().contains('tidak ditemukan') ||
            failure.toLowerCase().contains('not found')) {
          emit(AttendanceTodayNotFound());
        } else {
          emit(AttendanceTodayError(failure));
        }
      },
      (data) => emit(AttendanceTodayLoaded(data)),
    );
  }
}
