part of 'attendance_today_bloc.dart';

abstract class AttendanceTodayState {
  const AttendanceTodayState();
}

class AttendanceTodayInitial extends AttendanceTodayState {
  @override
  bool operator ==(Object other) => other is AttendanceTodayInitial;

  @override
  int get hashCode => runtimeType.hashCode;
}

class AttendanceTodayLoading extends AttendanceTodayState {
  @override
  bool operator ==(Object other) => other is AttendanceTodayLoading;

  @override
  int get hashCode => runtimeType.hashCode;
}

class AttendanceTodayLoaded extends AttendanceTodayState {
  final AttendanceTodayModel data;

  const AttendanceTodayLoaded(this.data);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AttendanceTodayLoaded && other.data == data;
  }

  @override
  int get hashCode => data.hashCode;
}

class AttendanceTodayNotFound extends AttendanceTodayState {
  @override
  bool operator ==(Object other) => other is AttendanceTodayNotFound;

  @override
  int get hashCode => runtimeType.hashCode;
}

class AttendanceTodayError extends AttendanceTodayState {
  final String message;

  const AttendanceTodayError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AttendanceTodayError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
