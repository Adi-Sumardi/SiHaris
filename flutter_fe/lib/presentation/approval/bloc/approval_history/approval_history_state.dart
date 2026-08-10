import 'package:equatable/equatable.dart';
import '../../../../data/models/responses/approval_history_model.dart';

abstract class ApprovalHistoryState extends Equatable {
  const ApprovalHistoryState();

  @override
  List<Object?> get props => [];
}

class ApprovalHistoryInitial extends ApprovalHistoryState {}

class ApprovalHistoryLoading extends ApprovalHistoryState {}

class ApprovalHistoryLoaded extends ApprovalHistoryState {
  final List<ApprovalHistoryModel> history;
  final bool hasReachedMax;

  const ApprovalHistoryLoaded({
    required this.history,
    this.hasReachedMax = false,
  });

  ApprovalHistoryLoaded copyWith({
    List<ApprovalHistoryModel>? history,
    bool? hasReachedMax,
  }) {
    return ApprovalHistoryLoaded(
      history: history ?? this.history,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [history, hasReachedMax];
}

class ApprovalHistoryError extends ApprovalHistoryState {
  final String message;

  const ApprovalHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
