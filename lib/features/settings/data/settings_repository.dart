import '../model/scout_settings.dart';
import '../model/tag_setting.dart';

abstract interface class SettingsRepository {
  Stream<ScoutSettings?> watchScoutSettings();
  Future<void> saveTags(List<TagSetting> tags);
  Future<void> saveScoutSettings(ScoutSettings settings);
}
