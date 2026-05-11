import '../data/settings_repository.dart';
import '../model/scout_settings.dart';

class LoadScoutSettings {
  const LoadScoutSettings(this._repository);

  final SettingsRepository _repository;

  Stream<ScoutSettings?> call() => _repository.watchScoutSettings();
}
