import 'package:equatable/equatable.dart';
import '../../../../data/models/responses/notification_model.dart';

abstract class NotificationListState extends Equatable {
  const NotificationListState();

  @override
  List<Object?> get props => [];
}

class NotificationListInitial extends NotificationListState {}

class NotificationListLoading extends NotificationListState {}

class NotificationListLoaded extends NotificationListState {
  final List<NotificationModel> notifications;
  final bool hasReachedMax;

  const NotificationListLoaded(
    this.notifications, {
    required this.hasReachedMax,
  });

  @override
  List<Object?> get props => [notifications, hasReachedMax];
}

class NotificationListError extends NotificationListState {
  final String message;

  const NotificationListError(this.message);

  @override
  List<Object?> get props => [message];
}
