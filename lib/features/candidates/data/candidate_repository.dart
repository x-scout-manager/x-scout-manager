import '../model/candidate.dart';

abstract interface class CandidateRepository {
  Stream<List<Candidate>> watchCandidates();
  Future<Candidate?> findById(String candidateId);
}
