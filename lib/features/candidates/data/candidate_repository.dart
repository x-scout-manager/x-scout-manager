import '../model/candidate.dart';
import '../model/candidate_page.dart';
import '../model/candidate_sync_run.dart';

abstract interface class CandidateRepository {
  Future<CandidatePage> loadCandidatePage({
    CandidatePageCursor? startAfter,
    int pageSize = 50,
  });
  Stream<List<CandidateSyncRun>> watchRecentSyncRuns();
  Future<Candidate?> findById(String candidateId);
}
