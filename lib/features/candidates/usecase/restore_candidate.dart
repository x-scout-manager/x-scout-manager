import '../data/candidate_functions_repository.dart';

class RestoreCandidate {
  const RestoreCandidate(this._repository);

  final CandidateFunctionsRepository _repository;

  Future<void> call(String candidateId) {
    return _repository.restoreCandidate(candidateId);
  }
}
