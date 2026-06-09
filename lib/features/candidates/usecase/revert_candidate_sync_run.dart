import '../data/candidate_functions_repository.dart';

class RevertCandidateSyncRun {
  const RevertCandidateSyncRun(this._repository);

  final CandidateFunctionsRepository _repository;

  Future<RevertCandidateSyncRunResult> call(String runId) {
    return _repository.revertCandidateSyncRun(runId);
  }
}
