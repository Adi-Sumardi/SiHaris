part of 'payslip_list_bloc.dart';

abstract class PayslipListState {
  const PayslipListState();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayslipListState && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

class PayslipListInitial extends PayslipListState {}

class PayslipListLoading extends PayslipListState {}

class PayslipListLoaded extends PayslipListState {
  final List<PayslipModel> payslips;
  final int year;

  const PayslipListLoaded(this.payslips, {required this.year});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PayslipListLoaded &&
        other.year == year &&
        other.payslips.length == payslips.length &&
        other.payslips.asMap().entries.every(
          (entry) => entry.value == payslips[entry.key],
        );
  }

  @override
  int get hashCode =>
      payslips.fold(0, (prev, element) => prev ^ element.hashCode) ^
      year.hashCode;
}

class PayslipListError extends PayslipListState {
  final String message;

  const PayslipListError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PayslipListError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
