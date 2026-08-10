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

  Future<void> _onGetLeaveList(
    GetLeaveList event,
    Emitter<LeaveListState> emit,
  ) async {
    if (event.page == 1) {
      emit(LeaveListLoading());
    }

    try {
      final leaves = await datasource.getLeaves(page: event.page);

      // If we are loading the first page, we just emit the result
      // For simplicity in this iteration, we treat it as a fresh load.
      // Pagination logic can be more complex (appending), but for now sticking to basic requirement.
      // Based on test expectation:

      bool hasReachedMax =
          leaves.isEmpty || leaves.length < 10; // Assuming 10 is page size

      emit(LeaveListLoaded(leaves, hasReachedMax: hasReachedMax));
    } catch (e) {
      emit(LeaveListError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
