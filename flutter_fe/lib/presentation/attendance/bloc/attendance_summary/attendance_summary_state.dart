part of 'attendance_summary_bloc.dart';

abstract class AttendanceSummaryState {
  const AttendanceSummaryState();
}

class AttendanceSummaryInitial extends AttendanceSummaryState {
  @override
  bool operator ==(Object other) => other is AttendanceSummaryInitial;

  @override
  int get hashCode => runtimeType.hashCode;
}

class AttendanceSummaryLoading extends AttendanceSummaryState {
  @override
  bool operator ==(Object other) => other is AttendanceSummaryLoading;

  @override
  int get hashCode => runtimeType.hashCode;
}

class AttendanceSummaryLoaded extends AttendanceSummaryState {
  final AttendanceSummaryModel data;

  const AttendanceSummaryLoaded(this.data);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AttendanceSummaryLoaded && other.data == data;
  }

  @override
  int get hashCode => data.hashCode;
}

class AttendanceSummaryError extends AttendanceSummaryState {
  final String message;

  const AttendanceSummaryError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AttendanceSummaryError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
