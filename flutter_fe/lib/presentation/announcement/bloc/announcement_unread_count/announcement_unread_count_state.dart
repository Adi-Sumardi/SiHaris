import 'package:equatable/equatable.dart';

abstract class AnnouncementUnreadCountState extends Equatable {
  const AnnouncementUnreadCountState();

  @override
  List<Object?> get props => [];
}

class AnnouncementUnreadCountInitial extends AnnouncementUnreadCountState {}

class AnnouncementUnreadCountLoading extends AnnouncementUnreadCountState {}

class AnnouncementUnreadCountLoaded extends AnnouncementUnreadCountState {
  final int count;

  const AnnouncementUnreadCountLoaded(this.count);

  @override
  List<Object?> get props => [count];
}

class AnnouncementUnreadCountError extends AnnouncementUnreadCountState {
  final String message;

  const AnnouncementUnreadCountError(this.message);

  @override
  List<Object?> get props => [message];
}
