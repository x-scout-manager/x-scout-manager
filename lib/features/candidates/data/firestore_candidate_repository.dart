import 'candidate_repository.dart';
import '../model/candidate.dart';

class FirestoreCandidateRepository implements CandidateRepository {
  const FirestoreCandidateRepository();

  @override
  Stream<List<Candidate>> watchCandidates() {
    return const Stream.empty();
  }

  @override
  Future<Candidate?> findById(String candidateId) async {
    return null;
  }
}
