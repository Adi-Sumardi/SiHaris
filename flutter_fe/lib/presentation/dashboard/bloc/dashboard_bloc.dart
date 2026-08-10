import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/dashboard_datasource.dart';
import '../../../data/datasources/dashboard_remote_datasource.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardDatasource _datasource;

  DashboardBloc({
    DashboardDatasource? datasource,
  })  : _datasource = datasource ?? DashboardRemoteDatasource(),
        super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<RefreshDashboard>(_onRefreshDashboard);
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    await _fetchDashboard(emit);
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    await _fetchDashboard(emit);
  }

  Future<void> _fetchDashboard(Emitter<DashboardState> emit) async {
    final result = await _datasource.getDashboard();

    result.fold(
      (error) => emit(DashboardError(error)),
      (response) {
        if (response.data != null) {
          emit(DashboardLoaded(response.data!));
        } else {
          emit(DashboardError('Data tidak ditemukan'));
        }
      },
    );
  }
}
