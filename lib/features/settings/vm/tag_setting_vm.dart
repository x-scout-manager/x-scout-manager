import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../model/tag_setting.dart';
import '../usecase/load_scout_settings.dart';
import '../usecase/save_tags.dart';

class TagSettingState {
  const TagSettingState({
    this.tags = const [],
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
    this.noticeMessage,
  });

  final List<TagSetting> tags;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? noticeMessage;

  TagSettingState copyWith({
    List<TagSetting>? tags,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? noticeMessage,
  }) {
    return TagSettingState(
      tags: tags ?? this.tags,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      noticeMessage: noticeMessage,
    );
  }
}

class TagSettingVm extends ChangeNotifier {
  TagSettingVm(this._loadScoutSettings, this._saveTags) {
    _subscription = _loadScoutSettings().listen(
      (settings) {
        _state = _state.copyWith(
          tags: (settings?.tags ?? const [])
              .map((tag) => TagSetting(tag: tag, isActive: true))
              .toList(),
          isLoading: false,
          isSaving: false,
        );
        notifyListeners();
      },
      onError: (_) {
        _state = const TagSettingState(
          isLoading: false,
          errorMessage: 'タグ設定の読み込みに失敗しました。',
        );
        notifyListeners();
      },
    );
  }

  final LoadScoutSettings _loadScoutSettings;
  final SaveTags _saveTags;
  late final StreamSubscription _subscription;

  TagSettingState _state = const TagSettingState();

  TagSettingState get state => _state;

  void addTag(String value) {
    final normalized = _normalizeTag(value);
    final validation = _validateNewTag(normalized);
    if (validation != null) {
      _state = _state.copyWith(errorMessage: validation);
      notifyListeners();
      return;
    }

    _state = _state.copyWith(
      tags: [
        ..._state.tags,
        TagSetting(tag: normalized, isActive: true),
      ],
      isSaving: false,
    );
    notifyListeners();
  }

  void removeTag(String tag) {
    _state = _state.copyWith(
      tags: _state.tags.where((item) => item.tag != tag).toList(),
      isSaving: false,
    );
    notifyListeners();
  }

  Future<void> save() async {
    if (_state.tags.isEmpty) {
      _state = _state.copyWith(
        isLoading: false,
        isSaving: false,
        errorMessage: 'タグを1件以上登録してください。',
      );
      notifyListeners();
      return;
    }

    _state = _state.copyWith(isLoading: false, isSaving: true);
    notifyListeners();

    try {
      await _saveTags(_state.tags);
      _state = _state.copyWith(
        isLoading: false,
        isSaving: false,
        noticeMessage: '保存しました。',
      );
      notifyListeners();
    } on AppError catch (error) {
      _state = _state.copyWith(
        isLoading: false,
        isSaving: false,
        errorMessage: error.message,
      );
      notifyListeners();
    } catch (_) {
      _state = _state.copyWith(
        isLoading: false,
        isSaving: false,
        errorMessage: 'タグ設定の保存に失敗しました。',
      );
      notifyListeners();
    }
  }

  String _normalizeTag(String value) {
    return value.trim().replaceFirst(RegExp('^#+'), '');
  }

  String? _validateNewTag(String value) {
    if (value.isEmpty) {
      return '空のタグは追加できません。';
    }
    if (_state.tags.any(
      (tag) => tag.tag.toLowerCase() == value.toLowerCase(),
    )) {
      return '同じタグは追加できません。';
    }
    return null;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
