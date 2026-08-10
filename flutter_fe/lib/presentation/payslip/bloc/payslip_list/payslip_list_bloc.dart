import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/payslip_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/payslip_model.dart';

part 'payslip_list_event.dart';
part 'payslip_list_state.dart';

class PayslipListBloc extends Bloc<PayslipListEvent, PayslipListState> {
  final PayslipRemoteDatasource datasource;

  static const _tag = 'PayslipListBloc';

  PayslipListBloc({required this.datasource}) : super(PayslipListInitial()) {
    on<GetPayslips>(_onGetPayslips);
    on<RefreshPayslips>(_onRefreshPayslips);
  }

  void _log(String message) {
    developer.log(message, name: _tag);
  }

  Future<void> _onGetPayslips(
    GetPayslips event,
    Emitter<PayslipListState> emit,
  ) async {
    _log('📋 GetPayslips event: year=${event.year}, page=${event.page}');
    emit(PayslipListLoading());
    try {
      final payslips = await datasource.getPayslips(
        year: event.year,
        page: event.page,
      );
      _log('✅ Loaded ${payslips.length} payslips');
      emit(PayslipListLoaded(payslips, year: event.year));
    } catch (e, stackTrace) {
      _log('❌ Error: $e');
      _log('📍 StackTrace: $stackTrace');
      emit(PayslipListError(e.toString()));
    }
  }

  Future<void> _onRefreshPayslips(
    RefreshPayslips event,
    Emitter<PayslipListState> emit,
  ) async {
    _log('🔄 RefreshPayslips event: year=${event.year}');
    emit(PayslipListLoading());
    try {
      final payslips = await datasource.getPayslips(year: event.year, page: 1);
      _log('✅ Refreshed ${payslips.length} payslips');
      emit(PayslipListLoaded(payslips, year: event.year));
    } catch (e, stackTrace) {
      _log('❌ Error: $e');
      _log('📍 StackTrace: $stackTrace');
      emit(PayslipListError(e.toString()));
    }
  }
}
