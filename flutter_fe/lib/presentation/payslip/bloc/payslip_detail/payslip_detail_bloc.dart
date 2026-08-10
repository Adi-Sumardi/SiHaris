import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/payslip_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/payslip_detail_model.dart';

part 'payslip_detail_event.dart';
part 'payslip_detail_state.dart';

class PayslipDetailBloc extends Bloc<PayslipDetailEvent, PayslipDetailState> {
  final PayslipRemoteDatasource datasource;

  PayslipDetailBloc({required this.datasource})
    : super(PayslipDetailInitial()) {
    on<GetPayslipDetail>(_onGetPayslipDetail);
  }

  Future<void> _onGetPayslipDetail(
    GetPayslipDetail event,
    Emitter<PayslipDetailState> emit,
  ) async {
    emit(PayslipDetailLoading());
    try {
      final detail = await datasource.getPayslipDetail(event.id);
      emit(PayslipDetailLoaded(detail));
    } catch (e) {
      emit(PayslipDetailError(e.toString()));
    }
  }
}
