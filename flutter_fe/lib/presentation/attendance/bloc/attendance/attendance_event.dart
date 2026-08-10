part of 'attendance_bloc.dart';

abstract class AttendanceEvent {
  const AttendanceEvent();
}

class AttendanceClockIn extends AttendanceEvent {
  final ClockInRequestModel request;

  const AttendanceClockIn(this.request);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AttendanceClockIn && other.request == request;
  }

  @override
  int get hashCode => request.hashCode;
}

class AttendanceClockOut extends AttendanceEvent {
  final ClockOutRequestModel request;

  const AttendanceClockOut(this.request);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AttendanceClockOut && other.request == request;
  }

  @override
  int get hashCode => request.hashCode;
}
