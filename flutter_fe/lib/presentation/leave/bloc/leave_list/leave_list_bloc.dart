import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/leave_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/leave_model.dart';

part 'leave_list_event.dart';
part 'leave_list_state.dart';

class LeaveListBloc extends Bloc<LeaveListEvent, LeaveListState> {
  final LeaveRemoteDatasource datasource;

  LeaveListBloc(this.datasource) : super(LeaveListInitial()) {
    on<GetLeaveList>(_onGetLeaveList);
  }

  /// Backend page size (`LeaveController::index()` calls `paginate(15)`).
  static const int _pageSize = 15;

  Future<void> _onGetLeaveList(
    GetLeaveList event,
    Emitter<LeaveListState> emit,
  ) async {
    if (event.page == 1) {
      emit(LeaveListLoading());
    }

    try {
      final leaves = await datasource.getLeaves(
        page: event.page,
        status: event.status,
        year: event.year,
      );

      final hasReachedMax = leaves.length < _pageSize;

      final currentState = state;
      final allLeaves = event.page > 1 && currentState is LeaveListLoaded
          ? [...currentState.leaves, ...leaves]
          : leaves;

      emit(LeaveListLoaded(allLeaves, hasReachedMax: hasReachedMax));
    } catch (e) {
      emit(LeaveListError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
