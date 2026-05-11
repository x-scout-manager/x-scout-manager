import 'template_repository.dart';
import '../model/dm_template.dart';

class FirestoreTemplateRepository implements TemplateRepository {
  const FirestoreTemplateRepository();

  @override
  Stream<List<DmTemplate>> watchTemplates() {
    return const Stream.empty();
  }

  @override
  Future<void> saveTemplate(DmTemplate template) async {}
}
