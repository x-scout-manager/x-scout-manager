abstract interface class CandidateFunctionsRepository {
  Future<void> syncCandidates();
  Future<void> excludeCandidate(String candidateId);
  Future<void> restoreCandidate(String candidateId);
}

class FirebaseCandidateFunctionsRepository
    implements CandidateFunctionsRepository {
  const FirebaseCandidateFunctionsRepository();

  @override
  Future<void> syncCandidates() async {}

  @override
  Future<void> excludeCandidate(String candidateId) async {}

  @override
  Future<void> restoreCandidate(String candidateId) async {}
}
