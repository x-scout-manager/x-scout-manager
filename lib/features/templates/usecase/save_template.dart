import '../data/template_repository.dart';
import '../model/dm_template.dart';

class SaveTemplate {
  const SaveTemplate(this._repository);

  final TemplateRepository _repository;

  Future<void> call(DmTemplate template) {
    return _repository.saveTemplate(template);
  }
}
