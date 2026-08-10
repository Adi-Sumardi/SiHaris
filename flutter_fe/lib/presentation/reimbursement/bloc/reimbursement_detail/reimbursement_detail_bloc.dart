import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gaji_pro/data/datasources/reimbursement_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/reimbursement_model.dart';

part 'reimbursement_detail_event.dart';
part 'reimbursement_detail_state.dart';

class ReimbursementDetailBloc
    extends Bloc<ReimbursementDetailEvent, ReimbursementDetailState> {
  final ReimbursementRemoteDatasource datasource;

  ReimbursementDetailBloc(this.datasource)
    : super(ReimbursementDetailInitial()) {
    on<LoadReimbursementDetail>(_onLoadReimbursementDetail);
  }

  Future<void> _onLoadReimbursementDetail(
    LoadReimbursementDetail event,
    Emitter<ReimbursementDetailState> emit,
  ) async {
    try {
      emit(ReimbursementDetailLoading());
      final reimbursement = await datasource.getReimbursementDetail(event.id);
      emit(ReimbursementDetailLoaded(reimbursement));
    } catch (e) {
      emit(ReimbursementDetailError(e.toString()));
    }
  }
}
