part of 'payslip_download_bloc.dart';

abstract class PayslipDownloadEvent {}

class DownloadPayslip extends PayslipDownloadEvent {
  final int id;

  DownloadPayslip(this.id);
}
