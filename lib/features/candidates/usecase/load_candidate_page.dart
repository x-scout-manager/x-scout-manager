import '../data/candidate_repository.dart';
import '../model/candidate_page.dart';

class LoadCandidatePage {
  const LoadCandidatePage(this._repository);

  final CandidateRepository _repository;

  Future<CandidatePage> call({
    CandidatePageCursor? startAfter,
    int pageSize = 50,
  }) {
    return _repository.loadCandidatePage(
      startAfter: startAfter,
      pageSize: pageSize,
    );
  }
}
