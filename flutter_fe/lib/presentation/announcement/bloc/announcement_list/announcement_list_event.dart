import 'package:equatable/equatable.dart';

abstract class AnnouncementListEvent extends Equatable {
  const AnnouncementListEvent();

  @override
  List<Object?> get props => [];
}

class LoadAnnouncements extends AnnouncementListEvent {
  const LoadAnnouncements();
}

class RefreshAnnouncements extends AnnouncementListEvent {
  const RefreshAnnouncements();
}

class LoadMoreAnnouncements extends AnnouncementListEvent {
  const LoadMoreAnnouncements();
}
