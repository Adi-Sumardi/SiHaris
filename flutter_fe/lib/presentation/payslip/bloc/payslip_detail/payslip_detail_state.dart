part of 'payslip_detail_bloc.dart';

abstract class PayslipDetailState {
  const PayslipDetailState();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayslipDetailState && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

class PayslipDetailInitial extends PayslipDetailState {}

class PayslipDetailLoading extends PayslipDetailState {}

class PayslipDetailLoaded extends PayslipDetailState {
  final PayslipDetailModel detail;

  const PayslipDetailLoaded(this.detail);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PayslipDetailLoaded && other.detail == detail;
  }

  @override
  int get hashCode => detail.hashCode;
}

class PayslipDetailError extends PayslipDetailState {
  final String message;

  const PayslipDetailError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PayslipDetailError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
