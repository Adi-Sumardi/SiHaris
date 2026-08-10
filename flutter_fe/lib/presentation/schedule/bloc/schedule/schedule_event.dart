part of 'schedule_bloc.dart';

abstract class ScheduleEvent {
  const ScheduleEvent();
}

class LoadSchedule extends ScheduleEvent {
  final String? month;

  const LoadSchedule({this.month});

  @override
  bool operator ==(Object other) =>
      other is LoadSchedule && other.month == month;

  @override
  int get hashCode => month.hashCode;
}
