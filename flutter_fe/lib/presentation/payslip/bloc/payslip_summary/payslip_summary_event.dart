part of 'payslip_summary_bloc.dart';

abstract class PayslipSummaryEvent {}

class GetPayslipSummary extends PayslipSummaryEvent {
  final int year;

  GetPayslipSummary({required this.year});
}
