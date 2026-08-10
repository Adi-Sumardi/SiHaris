part of 'attendance_bloc.dart';

abstract class AttendanceState {
  const AttendanceState();
}

class AttendanceInitial extends AttendanceState {
  @override
  bool operator ==(Object other) => other is AttendanceInitial;

  @override
  int get hashCode => runtimeType.hashCode;
}

class AttendanceLoading extends AttendanceState {
  @override
  bool operator ==(Object other) => other is AttendanceLoading;

  @override
  int get hashCode => runtimeType.hashCode;
}

class AttendanceSuccess extends AttendanceState {
  final String message;

  const AttendanceSuccess(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AttendanceSuccess && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

class AttendanceFailure extends AttendanceState {
  final String message;

  const AttendanceFailure(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AttendanceFailure && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
