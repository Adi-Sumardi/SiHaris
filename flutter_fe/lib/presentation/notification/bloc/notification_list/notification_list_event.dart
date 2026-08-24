import 'package:equatable/equatable.dart';

abstract class NotificationListEvent extends Equatable {
  const NotificationListEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationListEvent {
  const LoadNotifications();
}

class RefreshNotifications extends NotificationListEvent {
  const RefreshNotifications();
}

class LoadMoreNotifications extends NotificationListEvent {
  const LoadMoreNotifications();
}

class MarkNotificationAsRead extends NotificationListEvent {
  final int id;

  const MarkNotificationAsRead(this.id);

  @override
  List<Object?> get props => [id];
}

class MarkAllNotificationsAsRead extends NotificationListEvent {
  const MarkAllNotificationsAsRead();
}
