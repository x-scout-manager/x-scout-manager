import '../data/candidate_repository.dart';
import '../model/candidate_sync_run.dart';

class LoadCandidateSyncRuns {
  const LoadCandidateSyncRuns(this._repository);

  final CandidateRepository _repository;

  Stream<List<CandidateSyncRun>> call() => _repository.watchRecentSyncRuns();
}
