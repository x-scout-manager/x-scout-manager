import 'dashboard_repository.dart';
import '../model/dashboard_summary.dart';

class FirestoreDashboardRepository implements DashboardRepository {
  const FirestoreDashboardRepository();

  @override
  Future<DashboardSummary> loadSummary() async {
    return const DashboardSummary(
      candidateCount: 0,
      sentCount: 0,
      excludedCount: 0,
    );
  }
}
