import '../data/candidate_functions_repository.dart';

class ExcludeCandidate {
  const ExcludeCandidate(this._repository);

  final CandidateFunctionsRepository _repository;

  Future<void> call(String candidateId, {String? reason}) {
    return _repository.excludeCandidate(
      candidateId: candidateId,
      reason: reason,
    );
  }
}
