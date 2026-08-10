import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/dashboard_datasource.dart';
import 'attendance_chart_event.dart';
import 'attendance_chart_state.dart';

class AttendanceChartBloc
    extends Bloc<AttendanceChartEvent, AttendanceChartState> {
  final DashboardDatasource datasource;
  int _currentDays = 7;

  AttendanceChartBloc({required this.datasource})
      : super(AttendanceChartInitial()) {
    on<LoadAttendanceChart>(_onLoadAttendanceChart);
    on<RefreshAttendanceChart>(_onRefreshAttendanceChart);
    on<ChangeDays>(_onChangeDays);
  }

  Future<void> _onLoadAttendanceChart(
    LoadAttendanceChart event,
    Emitter<AttendanceChartState> emit,
  ) async {
    emit(AttendanceChartLoading());
    _currentDays = event.days;

    final result = await datasource.getAttendanceChart(days: event.days);

    result.fold(
      (error) => emit(AttendanceChartError(error)),
      (chartData) => emit(AttendanceChartLoaded(chartData, days: event.days)),
    );
  }

  Future<void> _onRefreshAttendanceChart(
    RefreshAttendanceChart event,
    Emitter<AttendanceChartState> emit,
  ) async {
    emit(AttendanceChartLoading());

    final result = await datasource.getAttendanceChart(days: _currentDays);

    result.fold(
      (error) => emit(AttendanceChartError(error)),
      (chartData) => emit(AttendanceChartLoaded(chartData, days: _currentDays)),
    );
  }

  Future<void> _onChangeDays(
    ChangeDays event,
    Emitter<AttendanceChartState> emit,
  ) async {
    emit(AttendanceChartLoading());
    _currentDays = event.days;

    final result = await datasource.getAttendanceChart(days: event.days);

    result.fold(
      (error) => emit(AttendanceChartError(error)),
      (chartData) => emit(AttendanceChartLoaded(chartData, days: event.days)),
    );
  }
}
