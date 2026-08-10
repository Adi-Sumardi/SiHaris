part of 'leave_types_bloc.dart';

abstract class LeaveTypesState {
  const LeaveTypesState();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaveTypesState && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

class LeaveTypesInitial extends LeaveTypesState {}

class LeaveTypesLoading extends LeaveTypesState {}

class LeaveTypesLoaded extends LeaveTypesState {
  final List<LeaveTypeModel> types;

  const LeaveTypesLoaded(this.types);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaveTypesLoaded &&
        other.types.length == types.length &&
        other.types.asMap().entries.every(
          (entry) => entry.value == types[entry.key],
        );
  }

  @override
  int get hashCode => types.fold(0, (prev, element) => prev ^ element.hashCode);
}

class LeaveTypesError extends LeaveTypesState {
  final String message;

  const LeaveTypesError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaveTypesError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
