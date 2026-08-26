import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/notification_remote_datasource.dart';
import 'notification_list_event.dart';
import 'notification_list_state.dart';

class NotificationListBloc
    extends Bloc<NotificationListEvent, NotificationListState> {
  final NotificationRemoteDatasource datasource;
  int _currentPage = 1;

  static const int pageSize = 20;

  NotificationListBloc(this.datasource) : super(NotificationListInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<RefreshNotifications>(_onRefreshNotifications);
    on<LoadMoreNotifications>(_onLoadMoreNotifications);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationListState> emit,
  ) async {
    emit(NotificationListLoading());
    try {
      _currentPage = 1;
      final notifications = await datasource.getNotifications(
        page: _currentPage,
      );
      emit(
        NotificationListLoaded(
          notifications,
          hasReachedMax: notifications.length < pageSize,
        ),
      );
    } catch (e) {
      emit(NotificationListError(e.toString()));
    }
  }

  Future<void> _onRefreshNotifications(
    RefreshNotifications event,
    Emitter<NotificationListState> emit,
  ) async {
    try {
      _currentPage = 1;
      final notifications = await datasource.getNotifications(
        page: _currentPage,
      );
      emit(
        NotificationListLoaded(
          notifications,
          hasReachedMax: notifications.length < pageSize,
        ),
      );
    } catch (e) {
      emit(NotificationListError(e.toString()));
    }
  }

  Future<void> _onLoadMoreNotifications(
    LoadMoreNotifications event,
    Emitter<NotificationListState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationListLoaded &&
        !currentState.hasReachedMax) {
      try {
        _currentPage++;
        final moreNotifications = await datasource.getNotifications(
          page: _currentPage,
        );
        emit(
          NotificationListLoaded([
            ...currentState.notifications,
            ...moreNotifications,
          ], hasReachedMax: moreNotifications.length < pageSize),
        );
      } catch (e) {
        // Keep current state on error
      }
    }
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationListState> emit,
  ) async {
    final currentState = state;
    try {
      await datasource.markAsRead(event.id);
      if (currentState is NotificationListLoaded) {
        emit(
          NotificationListLoaded(
            currentState.notifications
                .map((n) => n.id == event.id ? n.copyWith(isRead: true) : n)
                .toList(),
            hasReachedMax: currentState.hasReachedMax,
          ),
        );
      }
    } catch (e) {
      // Silently ignore — not critical enough to interrupt the list view.
    }
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationListState> emit,
  ) async {
    final currentState = state;
    try {
      await datasource.markAllAsRead();
      if (currentState is NotificationListLoaded) {
        emit(
          NotificationListLoaded(
            currentState.notifications
                .map((n) => n.copyWith(isRead: true))
                .toList(),
            hasReachedMax: currentState.hasReachedMax,
          ),
        );
      }
    } catch (e) {
      // Silently ignore — not critical enough to interrupt the list view.
    }
  }
}
