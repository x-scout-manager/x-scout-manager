import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/exclusion_keyword.dart';
import '../usecase/save_exclusion_keywords.dart';
import '../data/exclusion_repository.dart';

class ExclusionKeywordState {
  const ExclusionKeywordState({
    this.keywords = const [],
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
    this.noticeMessage,
  });

  final List<ExclusionKeyword> keywords;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? noticeMessage;
}

class ExclusionKeywordVm extends ChangeNotifier {
  ExclusionKeywordVm(this._repository, this._saveExclusionKeywords) {
    _subscription = _repository.watchKeywords().listen(
      (keywords) {
        _state = ExclusionKeywordState(keywords: keywords, isLoading: false);
        notifyListeners();
      },
      onError: (_) {
        _state = const ExclusionKeywordState(
          isLoading: false,
          errorMessage: '除外キーワードの読み込みに失敗しました。',
        );
        notifyListeners();
      },
    );
  }

  final ExclusionRepository _repository;
  final SaveExclusionKeywords _saveExclusionKeywords;
  late final StreamSubscription _subscription;

  ExclusionKeywordState _state = const ExclusionKeywordState();

  ExclusionKeywordState get state => _state;

  void addKeyword(String value) {
    final normalized = value.trim();
    final validation = _validateNewKeyword(normalized);
    if (validation != null) {
      _state = ExclusionKeywordState(
        keywords: _state.keywords,
        isLoading: _state.isLoading,
        isSaving: _state.isSaving,
        errorMessage: validation,
      );
      notifyListeners();
      return;
    }

    _state = ExclusionKeywordState(
      keywords: [
        ..._state.keywords,
        ExclusionKeyword(keyword: normalized, isActive: true),
      ],
      isLoading: _state.isLoading,
    );
    notifyListeners();
  }

  void removeKeyword(String keyword) {
    _state = ExclusionKeywordState(
      keywords: _state.keywords
          .where((item) => item.keyword != keyword)
          .toList(),
      isLoading: _state.isLoading,
    );
    notifyListeners();
  }

  Future<void> save() async {
    _state = ExclusionKeywordState(keywords: _state.keywords, isSaving: true);
    notifyListeners();

    try {
      await _saveExclusionKeywords(_state.keywords);
      _state = ExclusionKeywordState(
        keywords: _state.keywords,
        noticeMessage: '保存しました。',
      );
      notifyListeners();
    } catch (_) {
      _state = ExclusionKeywordState(
        keywords: _state.keywords,
        errorMessage: '除外キーワードの保存に失敗しました。',
      );
      notifyListeners();
    }
  }

  String? _validateNewKeyword(String value) {
    if (value.isEmpty) {
      return '空のキーワードは追加できません。';
    }
    if (_state.keywords.any(
      (keyword) => keyword.keyword.toLowerCase() == value.toLowerCase(),
    )) {
      return '同じキーワードは追加できません。';
    }
    return null;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
