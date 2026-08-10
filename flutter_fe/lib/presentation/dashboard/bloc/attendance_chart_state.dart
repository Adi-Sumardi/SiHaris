import 'package:gaji_pro/data/models/responses/dashboard/dashboard_models.dart';

abstract class AttendanceChartState {}

class AttendanceChartInitial extends AttendanceChartState {}

class AttendanceChartLoading extends AttendanceChartState {}

class AttendanceChartLoaded extends AttendanceChartState {
  final AttendanceChartModel chartData;
  final int days;

  AttendanceChartLoaded(this.chartData, {this.days = 7});
}

class AttendanceChartError extends AttendanceChartState {
  final String message;

  AttendanceChartError(this.message);
}
