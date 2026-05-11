import '../data/exclusion_repository.dart';
import '../model/excluded_account.dart';

class LoadExcludedAccounts {
  const LoadExcludedAccounts(this._repository);

  final ExclusionRepository _repository;

  Stream<List<ExcludedAccount>> call() {
    return _repository.watchExcludedAccounts();
  }
}
