import '../model/excluded_account.dart';
import '../model/exclusion_keyword.dart';

abstract interface class ExclusionRepository {
  Stream<List<ExcludedAccount>> watchExcludedAccounts();
  Stream<List<ExclusionKeyword>> watchKeywords();
  Future<void> saveKeywords(List<ExclusionKeyword> keywords);
}
