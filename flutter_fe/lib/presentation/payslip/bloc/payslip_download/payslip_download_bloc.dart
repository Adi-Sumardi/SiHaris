import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/payslip_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/payslip_download_model.dart';

part 'payslip_download_event.dart';
part 'payslip_download_state.dart';

class PayslipDownloadBloc
    extends Bloc<PayslipDownloadEvent, PayslipDownloadState> {
  final PayslipRemoteDatasource datasource;

  PayslipDownloadBloc({required this.datasource})
    : super(PayslipDownloadInitial()) {
    on<DownloadPayslip>(_onDownloadPayslip);
  }

  Future<void> _onDownloadPayslip(
    DownloadPayslip event,
    Emitter<PayslipDownloadState> emit,
  ) async {
    emit(PayslipDownloadLoading());
    try {
      final download = await datasource.downloadPayslip(event.id);
      emit(PayslipDownloadSuccess(download));
    } catch (e) {
      emit(PayslipDownloadError(e.toString()));
    }
  }
}
