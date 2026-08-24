import 'package:equatable/equatable.dart';

abstract class NotificationUnreadCountEvent extends Equatable {
  const NotificationUnreadCountEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotificationUnreadCount extends NotificationUnreadCountEvent {
  const LoadNotificationUnreadCount();
}

class RefreshNotificationUnreadCount extends NotificationUnreadCountEvent {
  const RefreshNotificationUnreadCount();
}
