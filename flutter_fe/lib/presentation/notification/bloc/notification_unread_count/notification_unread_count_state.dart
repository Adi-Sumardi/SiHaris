import 'package:equatable/equatable.dart';

abstract class NotificationUnreadCountState extends Equatable {
  const NotificationUnreadCountState();

  @override
  List<Object?> get props => [];
}

class NotificationUnreadCountInitial extends NotificationUnreadCountState {}

class NotificationUnreadCountLoading extends NotificationUnreadCountState {}

class NotificationUnreadCountLoaded extends NotificationUnreadCountState {
  final int count;

  const NotificationUnreadCountLoaded(this.count);

  @override
  List<Object?> get props => [count];
}

class NotificationUnreadCountError extends NotificationUnreadCountState {
  final String message;

  const NotificationUnreadCountError(this.message);

  @override
  List<Object?> get props => [message];
}
