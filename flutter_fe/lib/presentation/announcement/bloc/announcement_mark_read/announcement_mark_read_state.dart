import 'package:equatable/equatable.dart';

abstract class AnnouncementMarkReadState extends Equatable {
  const AnnouncementMarkReadState();

  @override
  List<Object?> get props => [];
}

class AnnouncementMarkReadInitial extends AnnouncementMarkReadState {}

class AnnouncementMarkReadLoading extends AnnouncementMarkReadState {}

class AnnouncementMarkReadSuccess extends AnnouncementMarkReadState {}

class AnnouncementMarkReadError extends AnnouncementMarkReadState {
  final String message;

  const AnnouncementMarkReadError(this.message);

  @override
  List<Object?> get props => [message];
}
