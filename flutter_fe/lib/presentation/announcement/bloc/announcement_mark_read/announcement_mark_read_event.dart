import 'package:equatable/equatable.dart';

abstract class AnnouncementMarkReadEvent extends Equatable {
  const AnnouncementMarkReadEvent();

  @override
  List<Object?> get props => [];
}

class MarkAnnouncementAsRead extends AnnouncementMarkReadEvent {
  final int id;

  const MarkAnnouncementAsRead(this.id);

  @override
  List<Object?> get props => [id];
}
