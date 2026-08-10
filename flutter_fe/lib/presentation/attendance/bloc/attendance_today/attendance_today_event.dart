part of 'attendance_today_bloc.dart';

abstract class AttendanceTodayEvent {
  const AttendanceTodayEvent();
}

class GetTodayStatus extends AttendanceTodayEvent {
  @override
  bool operator ==(Object other) => other is GetTodayStatus;

  @override
  int get hashCode => runtimeType.hashCode;
}
