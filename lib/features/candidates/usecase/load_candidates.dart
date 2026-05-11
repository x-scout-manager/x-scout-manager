import '../data/candidate_repository.dart';
import '../model/candidate.dart';

class LoadCandidates {
  const LoadCandidates(this._repository);

  final CandidateRepository _repository;

  Stream<List<Candidate>> call() => _repository.watchCandidates();
}
