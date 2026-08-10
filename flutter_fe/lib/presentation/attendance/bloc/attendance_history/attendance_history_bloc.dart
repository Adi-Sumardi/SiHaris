import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/attendance_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/attendance_history_model.dart';

part 'attendance_history_event.dart';
part 'attendance_history_state.dart';

class AttendanceHistoryBloc
    extends Bloc<AttendanceHistoryEvent, AttendanceHistoryState> {
  final AttendanceRemoteDatasource datasource;

  AttendanceHistoryBloc({required this.datasource})
    : super(AttendanceHistoryInitial()) {
    on<GetAttendanceHistory>(_onGetHistory);
  }

  Future<void> _onGetHistory(
    GetAttendanceHistory event,
    Emitter<AttendanceHistoryState> emit,
  ) async {
    emit(AttendanceHistoryLoading());
    final result = await datasource.getHistory(
      page: event.page,
      startDate: event.startDate,
      endDate: event.endDate,
    );
    result.fold(
      (failure) => emit(AttendanceHistoryError(failure)),
      (data) =>
          emit(AttendanceHistoryLoaded(data, hasReachedMax: data.isEmpty)),
    );
  }
}
