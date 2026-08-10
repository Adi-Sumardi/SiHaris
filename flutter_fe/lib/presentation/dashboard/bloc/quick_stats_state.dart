import 'package:gaji_pro/data/models/responses/dashboard/dashboard_models.dart';

abstract class QuickStatsState {}

class QuickStatsInitial extends QuickStatsState {}

class QuickStatsLoading extends QuickStatsState {}

class QuickStatsLoaded extends QuickStatsState {
  final QuickStatsModel stats;

  QuickStatsLoaded(this.stats);
}

class QuickStatsError extends QuickStatsState {
  final String message;

  QuickStatsError(this.message);
}
