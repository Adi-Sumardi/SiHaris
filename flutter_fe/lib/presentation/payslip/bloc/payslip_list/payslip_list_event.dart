part of 'payslip_list_bloc.dart';

abstract class PayslipListEvent {}

class GetPayslips extends PayslipListEvent {
  final int year;
  final int page;

  GetPayslips({required this.year, this.page = 1});
}

class RefreshPayslips extends PayslipListEvent {
  final int year;

  RefreshPayslips({required this.year});
}
