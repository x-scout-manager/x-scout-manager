import '../model/dashboard_summary.dart';

abstract interface class DashboardRepository {
  Future<DashboardSummary> loadSummary();
}
