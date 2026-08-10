part of 'leave_list_bloc.dart';

abstract class LeaveListState {
  const LeaveListState();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaveListState && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

class LeaveListInitial extends LeaveListState {}

class LeaveListLoading extends LeaveListState {}

class LeaveListLoaded extends LeaveListState {
  final List<LeaveModel> leaves;
  final bool hasReachedMax;

  const LeaveListLoaded(this.leaves, {this.hasReachedMax = false});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaveListLoaded &&
        other.hasReachedMax == hasReachedMax &&
        other.leaves.length == leaves.length &&
        other.leaves.asMap().entries.every(
          (entry) => entry.value == leaves[entry.key],
        );
  }

  @override
  int get hashCode =>
      leaves.fold(0, (prev, element) => prev ^ element.hashCode) ^
      hasReachedMax.hashCode;
}

class LeaveListError extends LeaveListState {
  final String message;

  const LeaveListError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaveListError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
