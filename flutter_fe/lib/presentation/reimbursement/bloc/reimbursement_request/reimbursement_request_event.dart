part of 'reimbursement_request_bloc.dart';

abstract class ReimbursementRequestEvent extends Equatable {
  const ReimbursementRequestEvent();

  @override
  List<Object?> get props => [];
}

class SubmitReimbursementRequest extends ReimbursementRequestEvent {
  final ReimbursementRequestModel request;
  final File? receiptFile;

  const SubmitReimbursementRequest(this.request, this.receiptFile);

  @override
  List<Object?> get props => [request, receiptFile];
}
