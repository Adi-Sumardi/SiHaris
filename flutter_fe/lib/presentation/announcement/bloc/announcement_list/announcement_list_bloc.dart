import 'package:bloc/bloc.dart';
import '../../../../data/datasources/announcement_remote_datasource.dart';
import 'announcement_list_event.dart';
import 'announcement_list_state.dart';

class AnnouncementListBloc
    extends Bloc<AnnouncementListEvent, AnnouncementListState> {
  final AnnouncementRemoteDatasource datasource;
  int _currentPage = 1;

  AnnouncementListBloc(this.datasource) : super(AnnouncementListInitial()) {
    on<LoadAnnouncements>(_onLoadAnnouncements);
    on<RefreshAnnouncements>(_onRefreshAnnouncements);
    on<LoadMoreAnnouncements>(_onLoadMoreAnnouncements);
  }

  Future<void> _onLoadAnnouncements(
    LoadAnnouncements event,
    Emitter<AnnouncementListState> emit,
  ) async {
    emit(AnnouncementListLoading());
    try {
      _currentPage = 1;
      final announcements = await datasource.getAnnouncements(
        page: _currentPage,
      );
      emit(
        AnnouncementListLoaded(
          announcements,
          hasReachedMax: announcements.isEmpty,
        ),
      );
    } catch (e) {
      emit(AnnouncementListError(e.toString()));
    }
  }

  Future<void> _onRefreshAnnouncements(
    RefreshAnnouncements event,
    Emitter<AnnouncementListState> emit,
  ) async {
    emit(AnnouncementListLoading());
    try {
      _currentPage = 1;
      final announcements = await datasource.getAnnouncements(
        page: _currentPage,
      );
      emit(
        AnnouncementListLoaded(
          announcements,
          hasReachedMax: announcements.isEmpty,
        ),
      );
    } catch (e) {
      emit(AnnouncementListError(e.toString()));
    }
  }

  Future<void> _onLoadMoreAnnouncements(
    LoadMoreAnnouncements event,
    Emitter<AnnouncementListState> emit,
  ) async {
    final currentState = state;
    if (currentState is AnnouncementListLoaded && !currentState.hasReachedMax) {
      try {
        _currentPage++;
        final moreAnnouncements = await datasource.getAnnouncements(
          page: _currentPage,
        );
        emit(
          AnnouncementListLoaded([
            ...currentState.announcements,
            ...moreAnnouncements,
          ], hasReachedMax: moreAnnouncements.isEmpty),
        );
      } catch (e) {
        // Keep current state on error
      }
    }
  }
}
