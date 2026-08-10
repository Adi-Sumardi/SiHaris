import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/payslip_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/payslip_summary_model.dart';

part 'payslip_summary_event.dart';
part 'payslip_summary_state.dart';

class PayslipSummaryBloc
    extends Bloc<PayslipSummaryEvent, PayslipSummaryState> {
  final PayslipRemoteDatasource datasource;

  PayslipSummaryBloc({required this.datasource})
    : super(PayslipSummaryInitial()) {
    on<GetPayslipSummary>(_onGetPayslipSummary);
  }

  Future<void> _onGetPayslipSummary(
    GetPayslipSummary event,
    Emitter<PayslipSummaryState> emit,
  ) async {
    emit(PayslipSummaryLoading());
    try {
      final summary = await datasource.getPayslipSummary(year: event.year);
      emit(PayslipSummaryLoaded(summary));
    } catch (e) {
      emit(PayslipSummaryError(e.toString()));
    }
  }
}
