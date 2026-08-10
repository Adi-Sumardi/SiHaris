abstract class AttendanceChartEvent {}

class LoadAttendanceChart extends AttendanceChartEvent {
  final int days;

  LoadAttendanceChart({this.days = 7});
}

class RefreshAttendanceChart extends AttendanceChartEvent {}

class ChangeDays extends AttendanceChartEvent {
  final int days;

  ChangeDays(this.days);
}
