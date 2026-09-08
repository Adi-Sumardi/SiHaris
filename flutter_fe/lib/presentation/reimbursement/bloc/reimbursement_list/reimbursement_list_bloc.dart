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

  /// Backend page size (`Api\V1\ReimbursementController::index()` calls `paginate(15)`).
  static const int _pageSize = 15;

  Future<void> _onLoadReimbursements(
    LoadReimbursements event,
    Emitter<ReimbursementListState> emit,
  ) async {
    if (event.page == 1) {
      emit(ReimbursementListLoading());
    }

    try {
      final reimbursements = await datasource.getReimbursements(
        status: event.status,
        startDate: event.startDate,
        endDate: event.endDate,
        page: event.page,
      );

      final hasReachedMax = reimbursements.length < _pageSize;

      final currentState = state;
      final allReimbursements =
          event.page > 1 && currentState is ReimbursementListLoaded
          ? [...currentState.reimbursements, ...reimbursements]
          : reimbursements;

      emit(
        ReimbursementListLoaded(
          allReimbursements,
          hasReachedMax: hasReachedMax,
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
          hasReachedMax: reimbursements.length < _pageSize,
        ),
      );
    } catch (e) {
      emit(ReimbursementListError(e.toString()));
    }
  }
}
