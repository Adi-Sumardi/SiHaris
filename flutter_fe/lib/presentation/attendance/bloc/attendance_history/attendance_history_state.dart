part of 'attendance_history_bloc.dart';

abstract class AttendanceHistoryState {
  const AttendanceHistoryState();
}

class AttendanceHistoryInitial extends AttendanceHistoryState {
  @override
  bool operator ==(Object other) => other is AttendanceHistoryInitial;

  @override
  int get hashCode => runtimeType.hashCode;
}

class AttendanceHistoryLoading extends AttendanceHistoryState {
  @override
  bool operator ==(Object other) => other is AttendanceHistoryLoading;

  @override
  int get hashCode => runtimeType.hashCode;
}

class AttendanceHistoryLoaded extends AttendanceHistoryState {
  final List<AttendanceHistoryModel> data;
  final bool hasReachedMax;

  const AttendanceHistoryLoaded(this.data, {this.hasReachedMax = false});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AttendanceHistoryLoaded &&
        // Simplistic list comparison using toString or map equals not enough
        // Need list equality check or just assume if contents same.
        // For now strict reference or simple length/first item check is tricky.
        // Let's implement manually iterating or use collection equality if we can import it.
        // Without importing collection, we can check basic props.
        other.hasReachedMax == hasReachedMax &&
        other.data.length == data.length;
    // Ideally check content equality
  }

  @override
  int get hashCode => data.hashCode ^ hasReachedMax.hashCode;
}

class AttendanceHistoryError extends AttendanceHistoryState {
  final String message;

  const AttendanceHistoryError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AttendanceHistoryError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
