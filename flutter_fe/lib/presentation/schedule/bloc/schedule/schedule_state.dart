part of 'schedule_bloc.dart';

abstract class ScheduleState {
  const ScheduleState();
}

class ScheduleInitial extends ScheduleState {
  @override
  bool operator ==(Object other) => other is ScheduleInitial;

  @override
  int get hashCode => runtimeType.hashCode;
}

class ScheduleLoading extends ScheduleState {
  @override
  bool operator ==(Object other) => other is ScheduleLoading;

  @override
  int get hashCode => runtimeType.hashCode;
}

class ScheduleLoaded extends ScheduleState {
  final EmployeeScheduleResponse data;

  const ScheduleLoaded(this.data);

  @override
  bool operator ==(Object other) =>
      other is ScheduleLoaded && other.data == data;

  @override
  int get hashCode => data.hashCode;
}

class ScheduleError extends ScheduleState {
  final String message;

  const ScheduleError(this.message);

  @override
  bool operator ==(Object other) =>
      other is ScheduleError && other.message == message;

  @override
  int get hashCode => message.hashCode;
}
