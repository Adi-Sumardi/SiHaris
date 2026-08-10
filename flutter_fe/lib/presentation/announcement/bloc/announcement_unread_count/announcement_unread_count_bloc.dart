import 'package:bloc/bloc.dart';
import '../../../../data/datasources/announcement_remote_datasource.dart';
import 'announcement_unread_count_event.dart';
import 'announcement_unread_count_state.dart';

class AnnouncementUnreadCountBloc
    extends Bloc<AnnouncementUnreadCountEvent, AnnouncementUnreadCountState> {
  final AnnouncementRemoteDatasource datasource;

  AnnouncementUnreadCountBloc(this.datasource)
    : super(AnnouncementUnreadCountInitial()) {
    on<LoadUnreadCount>(_onLoadUnreadCount);
    on<RefreshUnreadCount>(_onRefreshUnreadCount);
  }

  Future<void> _onLoadUnreadCount(
    LoadUnreadCount event,
    Emitter<AnnouncementUnreadCountState> emit,
  ) async {
    emit(AnnouncementUnreadCountLoading());
    try {
      final unreadCount = await datasource.getUnreadCount();
      emit(AnnouncementUnreadCountLoaded(unreadCount.count));
    } catch (e) {
      emit(AnnouncementUnreadCountError(e.toString()));
    }
  }

  Future<void> _onRefreshUnreadCount(
    RefreshUnreadCount event,
    Emitter<AnnouncementUnreadCountState> emit,
  ) async {
    emit(AnnouncementUnreadCountLoading());
    try {
      final unreadCount = await datasource.getUnreadCount();
      emit(AnnouncementUnreadCountLoaded(unreadCount.count));
    } catch (e) {
      emit(AnnouncementUnreadCountError(e.toString()));
    }
  }
}
