import 'package:equatable/equatable.dart';

abstract class ApprovalPendingEvent extends Equatable {
  const ApprovalPendingEvent();

  @override
  List<Object?> get props => [];
}

class LoadPendingApprovals extends ApprovalPendingEvent {
  const LoadPendingApprovals();
}

class RefreshPendingApprovals extends ApprovalPendingEvent {
  const RefreshPendingApprovals();
}
