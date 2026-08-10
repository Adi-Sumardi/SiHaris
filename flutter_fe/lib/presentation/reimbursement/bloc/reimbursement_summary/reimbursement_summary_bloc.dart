import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gaji_pro/data/datasources/reimbursement_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/reimbursement_summary_model.dart';

part 'reimbursement_summary_event.dart';
part 'reimbursement_summary_state.dart';

class ReimbursementSummaryBloc
    extends Bloc<ReimbursementSummaryEvent, ReimbursementSummaryState> {
  final ReimbursementRemoteDatasource datasource;

  ReimbursementSummaryBloc(this.datasource)
    : super(ReimbursementSummaryInitial()) {
    on<LoadReimbursementSummary>(_onLoadReimbursementSummary);
  }

  Future<void> _onLoadReimbursementSummary(
    LoadReimbursementSummary event,
    Emitter<ReimbursementSummaryState> emit,
  ) async {
    try {
      emit(ReimbursementSummaryLoading());
      final summary = await datasource.getSummary(
        month: event.month,
        year: event.year,
      );
      emit(ReimbursementSummaryLoaded(summary));
    } catch (e) {
      emit(ReimbursementSummaryError(e.toString()));
    }
  }
}
