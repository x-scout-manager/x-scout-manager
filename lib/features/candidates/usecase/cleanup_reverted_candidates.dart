import '../data/candidate_functions_repository.dart';

class CleanupRevertedCandidates {
  const CleanupRevertedCandidates(this._repository);

  final CandidateFunctionsRepository _repository;

  Future<CleanupRevertedCandidatesResult> call() {
    return _repository.cleanupRevertedCandidates();
  }
}
