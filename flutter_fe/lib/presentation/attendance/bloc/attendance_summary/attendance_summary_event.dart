part of 'attendance_summary_bloc.dart';

abstract class AttendanceSummaryEvent {
  const AttendanceSummaryEvent();
}

class GetAttendanceSummary extends AttendanceSummaryEvent {
  final int month;
  final int year;

  const GetAttendanceSummary({required this.month, required this.year});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GetAttendanceSummary &&
        other.month == month &&
        other.year == year;
  }

  @override
  int get hashCode => month.hashCode ^ year.hashCode;
}
