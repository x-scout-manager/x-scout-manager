import '../data/candidate_functions_repository.dart';

class ExcludeCandidate {
  const ExcludeCandidate(this._repository);

  final CandidateFunctionsRepository _repository;

  Future<void> call(String candidateId) {
    return _repository.excludeCandidate(candidateId);
  }
}
