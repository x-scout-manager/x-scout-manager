import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../model/dm_template.dart';
import '../usecase/load_templates.dart';
import '../usecase/save_template.dart';

class TemplateListState {
  const TemplateListState({
    this.templates = const [],
    this.editing = DmTemplate.empty,
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
    this.noticeMessage,
  });

  final List<DmTemplate> templates;
  final DmTemplate editing;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? noticeMessage;

  TemplateListState copyWith({
    List<DmTemplate>? templates,
    DmTemplate? editing,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? noticeMessage,
  }) {
    return TemplateListState(
      templates: templates ?? this.templates,
      editing: editing ?? this.editing,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      noticeMessage: noticeMessage,
    );
  }
}

class TemplateListVm extends ChangeNotifier {
  TemplateListVm(this._loadTemplates, this._saveTemplate) {
    _subscription = _loadTemplates().listen(
      (templates) {
        _state = _state.copyWith(
          templates: templates,
          isLoading: false,
          isSaving: false,
        );
        notifyListeners();
      },
      onError: (_) {
        _state = const TemplateListState(
          isLoading: false,
          errorMessage: 'テンプレートの読み込みに失敗しました。',
        );
        notifyListeners();
      },
    );
  }

  final LoadTemplates _loadTemplates;
  final SaveTemplate _saveTemplate;
  late final StreamSubscription _subscription;

  TemplateListState _state = const TemplateListState();

  TemplateListState get state => _state;

  void startCreate() {
    _state = _state.copyWith(
      editing: DmTemplate.empty,
      isLoading: false,
      isSaving: false,
    );
    notifyListeners();
  }

  void startEdit(DmTemplate template) {
    _state = _state.copyWith(
      editing: template,
      isLoading: false,
      isSaving: false,
    );
    notifyListeners();
  }

  void updateName(String name) {
    _state = _state.copyWith(
      editing: _state.editing.copyWith(name: name),
      isLoading: false,
      isSaving: false,
    );
    notifyListeners();
  }

  void updateBody(String body) {
    _state = _state.copyWith(
      editing: _state.editing.copyWith(body: body),
      isLoading: false,
      isSaving: false,
    );
    notifyListeners();
  }

  void updateIsActive(bool isActive) {
    _state = _state.copyWith(
      editing: _state.editing.copyWith(isActive: isActive),
      isLoading: false,
      isSaving: false,
    );
    notifyListeners();
  }

  Future<void> saveEditing() async {
    await _save(_state.editing);
  }

  Future<void> disable(DmTemplate template) async {
    await _save(template.copyWith(isActive: false));
  }

  Future<void> _save(DmTemplate template) async {
    final validation = _validate(template);
    if (validation != null) {
      _state = _state.copyWith(
        editing: template,
        isLoading: false,
        isSaving: false,
        errorMessage: validation,
      );
      notifyListeners();
      return;
    }

    _state = _state.copyWith(
      editing: template,
      isLoading: false,
      isSaving: true,
    );
    notifyListeners();

    try {
      await _saveTemplate(
        template.copyWith(
          name: template.name.trim(),
          body: template.body.trim(),
        ),
      );
      _state = _state.copyWith(
        editing: DmTemplate.empty,
        isLoading: false,
        isSaving: false,
        noticeMessage: '保存しました。',
      );
      notifyListeners();
    } on AppError catch (error) {
      _state = _state.copyWith(
        editing: template,
        isLoading: false,
        isSaving: false,
        errorMessage: error.message,
      );
      notifyListeners();
    } catch (_) {
      _state = _state.copyWith(
        editing: template,
        isLoading: false,
        isSaving: false,
        errorMessage: 'テンプレートの保存に失敗しました。',
      );
      notifyListeners();
    }
  }

  String? _validate(DmTemplate template) {
    if (template.name.trim().isEmpty) {
      return 'テンプレート名を入力してください。';
    }
    if (template.body.trim().isEmpty) {
      return '本文を入力してください。';
    }
    return null;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
