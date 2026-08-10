import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/attendance_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/attendance_summary_model.dart';

part 'attendance_summary_event.dart';
part 'attendance_summary_state.dart';

class AttendanceSummaryBloc
    extends Bloc<AttendanceSummaryEvent, AttendanceSummaryState> {
  final AttendanceRemoteDatasource datasource;

  AttendanceSummaryBloc({required this.datasource})
    : super(AttendanceSummaryInitial()) {
    on<GetAttendanceSummary>(_onGetSummary);
  }

  Future<void> _onGetSummary(
    GetAttendanceSummary event,
    Emitter<AttendanceSummaryState> emit,
  ) async {
    emit(AttendanceSummaryLoading());
    final result = await datasource.getSummary(
      month: event.month,
      year: event.year,
    );
    result.fold(
      (failure) => emit(AttendanceSummaryError(failure)),
      (data) => emit(AttendanceSummaryLoaded(data)),
    );
  }
}
