import 'package:dartz/dartz.dart';
import '../models/responses/dashboard/dashboard_models.dart';

abstract class DashboardDatasource {
  Future<Either<String, DashboardResponseModel>> getDashboard();
  Future<Either<String, QuickStatsModel>> getQuickStats();
  Future<Either<String, AttendanceChartModel>> getAttendanceChart({int days = 7});
}
