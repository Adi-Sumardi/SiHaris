import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/overtime_remote_datasource.dart';
import 'overtime_list_event.dart';
import 'overtime_list_state.dart';

class OvertimeListBloc extends Bloc<OvertimeListEvent, OvertimeListState> {
  final OvertimeRemoteDatasource datasource;

  OvertimeListBloc(this.datasource) : super(OvertimeListInitial()) {
    on<GetOvertimeList>(_onGetOvertimeList);
    on<LoadMoreOvertimeList>(_onLoadMoreOvertimeList);
    on<RefreshOvertimeList>(_onRefreshOvertimeList);
  }

  Future<void> _onGetOvertimeList(
    GetOvertimeList event,
    Emitter<OvertimeListState> emit,
  ) async {
    emit(OvertimeListLoading());
    try {
      final result = await datasource.getOvertimes(
        status: event.status,
        startDate: event.startDate,
        endDate: event.endDate,
        page: 1,
      );
      emit(
        OvertimeListLoaded(
          overtimes: result,
          hasReachedMax: result.length < 15,
          page: 1,
        ),
      );
    } catch (e) {
      emit(OvertimeListError(e.toString()));
    }
  }

  Future<void> _onLoadMoreOvertimeList(
    LoadMoreOvertimeList event,
    Emitter<OvertimeListState> emit,
  ) async {
    final currentState = state;
    if (currentState is OvertimeListLoaded && !currentState.hasReachedMax) {
      try {
        final nextPage = currentState.page + 1;
        final result = await datasource.getOvertimes(
          status: event.status,
          startDate: event.startDate,
          endDate: event.endDate,
          page: nextPage,
        );
        if (result.isEmpty || result.length < 15) {
          emit(
            currentState.copyWith(
              overtimes: currentState.overtimes + result,
              page: nextPage,
              hasReachedMax: true,
            ),
          );
        } else {
          emit(
            currentState.copyWith(
              overtimes: currentState.overtimes + result,
              page: nextPage,
              hasReachedMax: false,
            ),
          );
        }
      } catch (e) {
        emit(OvertimeListError(e.toString()));
      }
    }
  }

  Future<void> _onRefreshOvertimeList(
    RefreshOvertimeList event,
    Emitter<OvertimeListState> emit,
  ) async {
    try {
      final result = await datasource.getOvertimes(
        status: event.status,
        startDate: event.startDate,
        endDate: event.endDate,
        page: 1,
      );
      emit(
        OvertimeListLoaded(
          overtimes: result,
          hasReachedMax: result.length < 15,
          page: 1,
        ),
      );
    } catch (e) {
      emit(OvertimeListError(e.toString()));
    }
  }
}
