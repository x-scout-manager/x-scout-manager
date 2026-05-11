import '../data/dashboard_repository.dart';
import '../model/dashboard_summary.dart';

class LoadDashboardSummary {
  const LoadDashboardSummary(this._repository);

  final DashboardRepository _repository;

  Future<DashboardSummary> call() => _repository.loadSummary();
}
