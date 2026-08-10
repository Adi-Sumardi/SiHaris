import 'package:equatable/equatable.dart';

abstract class AnnouncementUnreadCountEvent extends Equatable {
  const AnnouncementUnreadCountEvent();

  @override
  List<Object?> get props => [];
}

class LoadUnreadCount extends AnnouncementUnreadCountEvent {
  const LoadUnreadCount();
}

class RefreshUnreadCount extends AnnouncementUnreadCountEvent {
  const RefreshUnreadCount();
}
