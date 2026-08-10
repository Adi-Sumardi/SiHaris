import 'package:equatable/equatable.dart';

abstract class AnnouncementDetailEvent extends Equatable {
  const AnnouncementDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadAnnouncementDetail extends AnnouncementDetailEvent {
  final int id;

  const LoadAnnouncementDetail(this.id);

  @override
  List<Object?> get props => [id];
}
