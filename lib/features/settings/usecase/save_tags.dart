import '../data/settings_repository.dart';
import '../model/tag_setting.dart';

class SaveTags {
  const SaveTags(this._repository);

  final SettingsRepository _repository;

  Future<void> call(List<TagSetting> tags) {
    return _repository.saveTags(tags);
  }
}
