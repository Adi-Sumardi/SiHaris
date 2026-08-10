import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/leave_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/leave_type_model.dart';

part 'leave_types_event.dart';
part 'leave_types_state.dart';

class LeaveTypesBloc extends Bloc<LeaveTypesEvent, LeaveTypesState> {
  final LeaveRemoteDatasource datasource;

  LeaveTypesBloc(this.datasource) : super(LeaveTypesInitial()) {
    on<GetLeaveTypes>(_onGetLeaveTypes);
  }

  Future<void> _onGetLeaveTypes(
    GetLeaveTypes event,
    Emitter<LeaveTypesState> emit,
  ) async {
    emit(LeaveTypesLoading());
    try {
      final types = await datasource.getLeaveTypes();
      emit(LeaveTypesLoaded(types));
    } catch (e) {
      emit(LeaveTypesError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
