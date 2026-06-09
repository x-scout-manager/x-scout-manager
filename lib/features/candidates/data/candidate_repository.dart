import '../model/candidate.dart';
import '../model/candidate_sync_run.dart';

abstract interface class CandidateRepository {
  Stream<List<Candidate>> watchCandidates();
  Stream<List<CandidateSyncRun>> watchRecentSyncRuns();
  Future<Candidate?> findById(String candidateId);
}
