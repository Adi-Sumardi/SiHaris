import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/leave_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/leave_balance_model.dart';

part 'leave_balance_event.dart';
part 'leave_balance_state.dart';

class LeaveBalanceBloc extends Bloc<LeaveBalanceEvent, LeaveBalanceState> {
  final LeaveRemoteDatasource datasource;

  LeaveBalanceBloc(this.datasource) : super(LeaveBalanceInitial()) {
    on<GetLeaveBalance>(_onGetLeaveBalance);
  }

  Future<void> _onGetLeaveBalance(
    GetLeaveBalance event,
    Emitter<LeaveBalanceState> emit,
  ) async {
    emit(LeaveBalanceLoading());
    try {
      final balance = await datasource.getLeaveBalances();
      emit(LeaveBalanceLoaded(balance));
    } catch (e) {
      emit(LeaveBalanceError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
