part of 'attendance_history_bloc.dart';

abstract class AttendanceHistoryEvent {
  const AttendanceHistoryEvent();
}

class GetAttendanceHistory extends AttendanceHistoryEvent {
  final int page;
  final String? startDate;
  final String? endDate;

  const GetAttendanceHistory({this.page = 1, this.startDate, this.endDate});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GetAttendanceHistory &&
        other.page == page &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => page.hashCode ^ startDate.hashCode ^ endDate.hashCode;
}
