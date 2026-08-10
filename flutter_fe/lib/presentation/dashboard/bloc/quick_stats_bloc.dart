import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/dashboard_datasource.dart';
import 'quick_stats_event.dart';
import 'quick_stats_state.dart';

class QuickStatsBloc extends Bloc<QuickStatsEvent, QuickStatsState> {
  final DashboardDatasource datasource;

  QuickStatsBloc({required this.datasource}) : super(QuickStatsInitial()) {
    on<LoadQuickStats>(_onLoadQuickStats);
    on<RefreshQuickStats>(_onRefreshQuickStats);
  }

  Future<void> _onLoadQuickStats(
    LoadQuickStats event,
    Emitter<QuickStatsState> emit,
  ) async {
    emit(QuickStatsLoading());

    final result = await datasource.getQuickStats();

    result.fold(
      (error) => emit(QuickStatsError(error)),
      (stats) => emit(QuickStatsLoaded(stats)),
    );
  }

  Future<void> _onRefreshQuickStats(
    RefreshQuickStats event,
    Emitter<QuickStatsState> emit,
  ) async {
    emit(QuickStatsLoading());

    final result = await datasource.getQuickStats();

    result.fold(
      (error) => emit(QuickStatsError(error)),
      (stats) => emit(QuickStatsLoaded(stats)),
    );
  }
}
