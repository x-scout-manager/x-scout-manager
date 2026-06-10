import '../data/template_repository.dart';

class DeleteTemplate {
  const DeleteTemplate(this._repository);

  final TemplateRepository _repository;

  Future<void> call(String templateId) {
    return _repository.deleteTemplate(templateId);
  }
}
