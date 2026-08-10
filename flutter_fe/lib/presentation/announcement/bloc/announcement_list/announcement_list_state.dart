import 'package:equatable/equatable.dart';
import '../../../../data/models/responses/announcement_model.dart';

abstract class AnnouncementListState extends Equatable {
  const AnnouncementListState();

  @override
  List<Object?> get props => [];
}

class AnnouncementListInitial extends AnnouncementListState {}

class AnnouncementListLoading extends AnnouncementListState {}

class AnnouncementListLoaded extends AnnouncementListState {
  final List<AnnouncementModel> announcements;
  final bool hasReachedMax;

  const AnnouncementListLoaded(
    this.announcements, {
    required this.hasReachedMax,
  });

  @override
  List<Object?> get props => [announcements, hasReachedMax];
}

class AnnouncementListError extends AnnouncementListState {
  final String message;

  const AnnouncementListError(this.message);

  @override
  List<Object?> get props => [message];
}
