import '../data/candidate_functions_repository.dart';

class SyncCandidates {
  const SyncCandidates(this._repository);

  final CandidateFunctionsRepository _repository;

  Future<SyncCandidatesResult> call() => _repository.syncCandidates();
}
