import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gaji_pro/data/datasources/reimbursement_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/reimbursement_model.dart';

part 'reimbursement_list_event.dart';
part 'reimbursement_list_state.dart';

class ReimbursementListBloc
    extends Bloc<ReimbursementListEvent, ReimbursementListState> {
  final ReimbursementRemoteDatasource datasource;

  ReimbursementListBloc(this.datasource) : super(ReimbursementListInitial()) {
    on<LoadReimbursements>(_onLoadReimbursements);
    on<RefreshReimbursements>(_onRefreshReimbursements);
  }

  Future<void> _onLoadReimbursements(
    LoadReimbursements event,
    Emitter<ReimbursementListState> emit,
  ) async {
    try {
      emit(ReimbursementListLoading());
      final reimbursements = await datasource.getReimbursements(
        status: event.status,
        startDate: event.startDate,
        endDate: event.endDate,
        page: event.page,
      );
      emit(
        ReimbursementListLoaded(
          reimbursements,
          hasReachedMax: reimbursements.isEmpty,
        ),
      );
    } catch (e) {
      emit(ReimbursementListError(e.toString()));
    }
  }

  Future<void> _onRefreshReimbursements(
    RefreshReimbursements event,
    Emitter<ReimbursementListState> emit,
  ) async {
    try {
      emit(ReimbursementListLoading());
      final reimbursements = await datasource.getReimbursements(
        status: event.status,
        startDate: event.startDate,
        endDate: event.endDate,
        page: 1,
      );
      emit(
        ReimbursementListLoaded(
          reimbursements,
          hasReachedMax: reimbursements.isEmpty,
        ),
      );
    } catch (e) {
      emit(ReimbursementListError(e.toString()));
    }
  }
}
