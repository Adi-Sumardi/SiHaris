import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/notification_remote_datasource.dart';
import 'notification_unread_count_event.dart';
import 'notification_unread_count_state.dart';

class NotificationUnreadCountBloc
    extends Bloc<NotificationUnreadCountEvent, NotificationUnreadCountState> {
  final NotificationRemoteDatasource datasource;

  NotificationUnreadCountBloc(this.datasource)
    : super(NotificationUnreadCountInitial()) {
    on<LoadNotificationUnreadCount>(_onLoad);
    on<RefreshNotificationUnreadCount>(_onLoad);
  }

  Future<void> _onLoad(
    NotificationUnreadCountEvent event,
    Emitter<NotificationUnreadCountState> emit,
  ) async {
    emit(NotificationUnreadCountLoading());
    try {
      final unreadCount = await datasource.getUnreadCount();
      emit(NotificationUnreadCountLoaded(unreadCount.count));
    } catch (e) {
      emit(NotificationUnreadCountError(e.toString()));
    }
  }
}
