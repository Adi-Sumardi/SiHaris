import 'package:bloc/bloc.dart';
import '../../../../data/datasources/announcement_remote_datasource.dart';
import 'announcement_detail_event.dart';
import 'announcement_detail_state.dart';

class AnnouncementDetailBloc
    extends Bloc<AnnouncementDetailEvent, AnnouncementDetailState> {
  final AnnouncementRemoteDatasource datasource;

  AnnouncementDetailBloc(this.datasource) : super(AnnouncementDetailInitial()) {
    on<LoadAnnouncementDetail>(_onLoadAnnouncementDetail);
  }

  Future<void> _onLoadAnnouncementDetail(
    LoadAnnouncementDetail event,
    Emitter<AnnouncementDetailState> emit,
  ) async {
    emit(AnnouncementDetailLoading());
    try {
      final announcement = await datasource.getAnnouncementDetail(event.id);
      emit(AnnouncementDetailLoaded(announcement));
    } catch (e) {
      emit(AnnouncementDetailError(e.toString()));
    }
  }
}
