import '../data/template_repository.dart';
import '../model/dm_template.dart';

class LoadTemplates {
  const LoadTemplates(this._repository);

  final TemplateRepository _repository;

  Stream<List<DmTemplate>> call() => _repository.watchTemplates();
}
