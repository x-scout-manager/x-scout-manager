import '../data/settings_repository.dart';
import '../model/scout_settings.dart';

class SaveScoutSettings {
  const SaveScoutSettings(this._repository);

  final SettingsRepository _repository;

  Future<void> call(ScoutSettings settings) {
    return _repository.saveScoutSettings(settings);
  }
}
