import 'package:equatable/equatable.dart';

abstract class ApprovalHistoryEvent extends Equatable {
  const ApprovalHistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadApprovalHistory extends ApprovalHistoryEvent {
  const LoadApprovalHistory();
}

class RefreshApprovalHistory extends ApprovalHistoryEvent {
  const RefreshApprovalHistory();
}

class LoadMoreApprovalHistory extends ApprovalHistoryEvent {
  const LoadMoreApprovalHistory();
}
