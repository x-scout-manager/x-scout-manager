import 'exclusion_repository.dart';
import '../model/excluded_account.dart';
import '../model/exclusion_keyword.dart';

class FirestoreExclusionRepository implements ExclusionRepository {
  const FirestoreExclusionRepository();

  @override
  Stream<List<ExcludedAccount>> watchExcludedAccounts() {
    return const Stream.empty();
  }

  @override
  Stream<List<ExclusionKeyword>> watchKeywords() {
    return const Stream.empty();
  }

  @override
  Future<void> saveKeywords(List<ExclusionKeyword> keywords) async {}
}
