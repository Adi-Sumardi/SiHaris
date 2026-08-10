part of 'leave_balance_bloc.dart';

abstract class LeaveBalanceState {
  const LeaveBalanceState();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaveBalanceState && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

class LeaveBalanceInitial extends LeaveBalanceState {}

class LeaveBalanceLoading extends LeaveBalanceState {}

class LeaveBalanceLoaded extends LeaveBalanceState {
  final List<LeaveBalanceModel> balances;

  const LeaveBalanceLoaded(this.balances);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaveBalanceLoaded && other.balances == balances;
  }

  @override
  int get hashCode => balances.hashCode;
}

class LeaveBalanceError extends LeaveBalanceState {
  final String message;

  const LeaveBalanceError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaveBalanceError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
