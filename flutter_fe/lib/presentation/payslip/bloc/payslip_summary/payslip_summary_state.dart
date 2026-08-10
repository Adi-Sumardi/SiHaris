part of 'payslip_summary_bloc.dart';

abstract class PayslipSummaryState {
  const PayslipSummaryState();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayslipSummaryState && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

class PayslipSummaryInitial extends PayslipSummaryState {}

class PayslipSummaryLoading extends PayslipSummaryState {}

class PayslipSummaryLoaded extends PayslipSummaryState {
  final PayslipSummaryModel summary;

  const PayslipSummaryLoaded(this.summary);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PayslipSummaryLoaded && other.summary == summary;
  }

  @override
  int get hashCode => summary.hashCode;
}

class PayslipSummaryError extends PayslipSummaryState {
  final String message;

  const PayslipSummaryError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PayslipSummaryError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
