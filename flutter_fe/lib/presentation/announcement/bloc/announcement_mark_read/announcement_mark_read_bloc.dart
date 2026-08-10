import 'package:bloc/bloc.dart';
import '../../../../data/datasources/announcement_remote_datasource.dart';
import 'announcement_mark_read_event.dart';
import 'announcement_mark_read_state.dart';

class AnnouncementMarkReadBloc
    extends Bloc<AnnouncementMarkReadEvent, AnnouncementMarkReadState> {
  final AnnouncementRemoteDatasource datasource;

  AnnouncementMarkReadBloc(this.datasource)
    : super(AnnouncementMarkReadInitial()) {
    on<MarkAnnouncementAsRead>(_onMarkAnnouncementAsRead);
  }

  Future<void> _onMarkAnnouncementAsRead(
    MarkAnnouncementAsRead event,
    Emitter<AnnouncementMarkReadState> emit,
  ) async {
    emit(AnnouncementMarkReadLoading());
    try {
      await datasource.markAsRead(event.id);
      emit(AnnouncementMarkReadSuccess());
    } catch (e) {
      emit(AnnouncementMarkReadError(e.toString()));
    }
  }
}
