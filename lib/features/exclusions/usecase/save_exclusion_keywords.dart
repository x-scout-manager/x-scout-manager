import '../data/exclusion_repository.dart';
import '../model/exclusion_keyword.dart';

class SaveExclusionKeywords {
  const SaveExclusionKeywords(this._repository);

  final ExclusionRepository _repository;

  Future<void> call(List<ExclusionKeyword> keywords) {
    return _repository.saveKeywords(keywords);
  }
}
