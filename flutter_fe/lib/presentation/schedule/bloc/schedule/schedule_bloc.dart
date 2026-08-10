import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/schedule_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/employee_schedule_model.dart';

part 'schedule_event.dart';
part 'schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final ScheduleRemoteDatasource datasource;

  ScheduleBloc({required this.datasource}) : super(ScheduleInitial()) {
    on<LoadSchedule>(_onLoadSchedule);
  }

  Future<void> _onLoadSchedule(
    LoadSchedule event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ScheduleLoading());
    final result = await datasource.getMonthlySchedule(month: event.month);
    result.fold(
      (failure) => emit(ScheduleError(failure)),
      (data) => emit(ScheduleLoaded(data)),
    );
  }
}
