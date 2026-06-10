import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/scout_settings.dart';
import '../usecase/load_scout_settings.dart';
import '../usecase/save_scout_settings.dart';

class SystemSettingState {
  const SystemSettingState({
    this.settings = ScoutSettings.defaults,
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
    this.noticeMessage,
  });

  final ScoutSettings settings;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? noticeMessage;

  SystemSettingState copyWith({
    ScoutSettings? settings,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? noticeMessage,
  }) {
    return SystemSettingState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      noticeMessage: noticeMessage,
    );
  }
}

class SystemSettingVm extends ChangeNotifier {
  SystemSettingVm(this._loadScoutSettings, this._saveScoutSettings) {
    _subscription = _loadScoutSettings().listen(
      (settings) {
        _state = _state.copyWith(
          settings: settings ?? ScoutSettings.defaults,
          isLoading: false,
          isSaving: false,
        );
        notifyListeners();
      },
      onError: (_) {
        _state = const SystemSettingState(
          isLoading: false,
          errorMessage: 'システム設定の読み込みに失敗しました。',
        );
        notifyListeners();
      },
    );
  }

  final LoadScoutSettings _loadScoutSettings;
  final SaveScoutSettings _saveScoutSettings;
  late final StreamSubscription _subscription;

  SystemSettingState _state = const SystemSettingState();

  SystemSettingState get state => _state;

  void update({
    int? searchMaxResults,
    int? searchMaxPages,
    int? recentSearchDays,
    num? defaultRewardRate,
    bool? apiDmEnabled,
    bool? manualSendEnabled,
  }) {
    _state = _state.copyWith(
      settings: _state.settings.copyWith(
        searchMaxResults: searchMaxResults,
        searchMaxPages: searchMaxPages,
        recentSearchDays: recentSearchDays,
        defaultRewardRate: defaultRewardRate,
        apiDmEnabled: apiDmEnabled,
        manualSendEnabled: manualSendEnabled,
      ),
      isSaving: false,
    );
    notifyListeners();
  }

  Future<void> save() async {
    final validation = _validate(_state.settings);
    if (validation != null) {
      _state = _state.copyWith(
        isLoading: false,
        isSaving: false,
        errorMessage: validation,
      );
      notifyListeners();
      return;
    }

    _state = _state.copyWith(isLoading: false, isSaving: true);
    notifyListeners();

    try {
      await _saveScoutSettings(_state.settings);
      _state = _state.copyWith(
        isLoading: false,
        isSaving: false,
        noticeMessage: '保存しました。',
      );
      notifyListeners();
    } catch (_) {
      _state = _state.copyWith(
        isLoading: false,
        isSaving: false,
        errorMessage: 'システム設定の保存に失敗しました。',
      );
      notifyListeners();
    }
  }

  String? _validate(ScoutSettings settings) {
    if (settings.searchMaxResults < 1 || settings.searchMaxResults > 100) {
      return '検索取得件数は1〜100で入力してください。';
    }
    if (settings.searchMaxPages < 1 || settings.searchMaxPages > 10) {
      return '最大ページ数は1〜10で入力してください。';
    }
    if (settings.recentSearchDays < 1 || settings.recentSearchDays > 30) {
      return '検索対象日数は1〜30で入力してください。';
    }
    return null;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
