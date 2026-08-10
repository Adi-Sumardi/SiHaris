import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/leave_remote_datasource.dart';
import 'package:gaji_pro/data/models/requests/leave_request_model.dart';

part 'leave_crud_event.dart';
part 'leave_crud_state.dart';

class LeaveCrudBloc extends Bloc<LeaveCrudEvent, LeaveCrudState> {
  final LeaveRemoteDatasource datasource;

  LeaveCrudBloc(this.datasource) : super(LeaveCrudInitial()) {
    on<CreateLeave>(_onCreateLeave);
    on<CancelLeave>(_onCancelLeave);
  }

  Future<void> _onCreateLeave(
    CreateLeave event,
    Emitter<LeaveCrudState> emit,
  ) async {
    emit(LeaveCrudLoading());
    try {
      await datasource.createLeaveRequest(event.request);
      emit(const LeaveCrudSuccess('Berhasil membuat pengajuan cuti'));
    } catch (e) {
      emit(LeaveCrudFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCancelLeave(
    CancelLeave event,
    Emitter<LeaveCrudState> emit,
  ) async {
    emit(LeaveCrudLoading());
    try {
      await datasource.cancelLeaveRequest(event.id, event.reason);
      emit(const LeaveCrudSuccess('Berhasil membatalkan pengajuan cuti'));
    } catch (e) {
      emit(LeaveCrudFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
