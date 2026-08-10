part of 'payslip_detail_bloc.dart';

abstract class PayslipDetailEvent {}

class GetPayslipDetail extends PayslipDetailEvent {
  final int id;

  GetPayslipDetail(this.id);
}
