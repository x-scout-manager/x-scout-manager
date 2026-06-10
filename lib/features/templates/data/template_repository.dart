import '../model/dm_template.dart';

abstract interface class TemplateRepository {
  Stream<List<DmTemplate>> watchTemplates();
  Future<void> saveTemplate(DmTemplate template);
  Future<void> deleteTemplate(String templateId);
}
