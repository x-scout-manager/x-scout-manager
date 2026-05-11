import 'settings_repository.dart';
import '../model/scout_settings.dart';
import '../model/tag_setting.dart';

class FirestoreSettingsRepository implements SettingsRepository {
  const FirestoreSettingsRepository();

  @override
  Stream<ScoutSettings?> watchScoutSettings() {
    return const Stream.empty();
  }

  @override
  Future<void> saveScoutSettings(ScoutSettings settings) async {}

  @override
  Future<void> saveTags(List<TagSetting> tags) async {}
}
