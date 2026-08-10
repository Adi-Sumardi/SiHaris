import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gaji_pro/data/datasources/reimbursement_remote_datasource.dart';
import 'package:gaji_pro/data/models/requests/reimbursement_request_model.dart';
import 'package:gaji_pro/data/models/responses/reimbursement_model.dart';

part 'reimbursement_request_event.dart';
part 'reimbursement_request_state.dart';

class ReimbursementRequestBloc
    extends Bloc<ReimbursementRequestEvent, ReimbursementRequestState> {
  final ReimbursementRemoteDatasource datasource;

  ReimbursementRequestBloc(this.datasource)
    : super(ReimbursementRequestInitial()) {
    on<SubmitReimbursementRequest>(_onSubmitReimbursementRequest);
  }

  Future<void> _onSubmitReimbursementRequest(
    SubmitReimbursementRequest event,
    Emitter<ReimbursementRequestState> emit,
  ) async {
    try {
      emit(ReimbursementRequestSubmitting());
      final reimbursement = await datasource.createReimbursement(
        event.request,
        event.receiptFile,
      );
      emit(ReimbursementRequestSuccess(reimbursement));
    } catch (e) {
      emit(ReimbursementRequestError(e.toString()));
    }
  }
}
