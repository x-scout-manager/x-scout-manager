import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../templates/model/dm_template.dart';
import '../../templates/usecase/load_templates.dart';
import '../../settings/model/scout_settings.dart';
import '../../settings/usecase/load_scout_settings.dart';
import '../model/send_queue.dart';
import '../model/send_queue_item.dart';
import '../usecase/delete_send_queue.dart';
import '../usecase/load_send_queue.dart';
import '../usecase/load_send_queue_items.dart';
import '../usecase/mark_as_manually_sent.dart';
import '../usecase/send_direct_message.dart';

class SendQueueState {
  const SendQueueState({
    this.queue,
    this.items = const [],
    this.templates = const [],
    this.selectedTemplateId,
    this.selectedItemId,
    this.settings = ScoutSettings.defaults,
    this.isLoading = true,
    this.isProcessing = false,
    this.errorMessage,
    this.noticeMessage,
  });

  final SendQueue? queue;
  final List<SendQueueItem> items;
  final List<DmTemplate> templates;
  final String? selectedTemplateId;
  final String? selectedItemId;
  final ScoutSettings settings;
  final bool isLoading;
  final bool isProcessing;
  final String? errorMessage;
  final String? noticeMessage;

  SendQueueState copyWith({
    SendQueue? queue,
    List<SendQueueItem>? items,
    List<DmTemplate>? templates,
    String? selectedTemplateId,
    String? selectedItemId,
    ScoutSettings? settings,
    bool? isLoading,
    bool? isProcessing,
    String? errorMessage,
    String? noticeMessage,
    bool clearSelectedItem = false,
  }) {
    return SendQueueState(
      queue: queue ?? this.queue,
      items: items ?? this.items,
      templates: templates ?? this.templates,
      selectedTemplateId: selectedTemplateId ?? this.selectedTemplateId,
      selectedItemId: clearSelectedItem
          ? null
          : selectedItemId ?? this.selectedItemId,
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage,
      noticeMessage: noticeMessage,
    );
  }

  SendQueueItem? get selectedItem {
    for (final item in items) {
      if (item.itemId == selectedItemId) {
        return item;
      }
    }
    return items.where((item) => item.isSendable).firstOrNull;
  }

  DmTemplate? get selectedTemplate {
    for (final template in templates) {
      if (template.templateId == selectedTemplateId) {
        return template;
      }
    }
    return templates.where((template) => template.isActive).firstOrNull;
  }

  String get messageBody {
    final template = selectedTemplate;
    final item = selectedItem;
    if (template == null || item == null) {
      return '';
    }

    final displayName = item.displayName?.trim().isNotEmpty == true
        ? item.displayName!.trim()
        : item.username.isNotEmpty
        ? item.username
        : item.xUserId;
    return template.body
        .replaceAll('{{username}}', item.username)
        .replaceAll('{{displayName}}', displayName);
  }

  String get messagePreview {
    if (selectedItem == null) {
      return '送信対象は未選択です';
    }
    final template = selectedTemplate;
    if (template == null) {
      return 'テンプレートは未選択です';
    }
    if (template.body.trim().isEmpty) {
      return 'テンプレート本文が空です';
    }
    final body = messageBody.trim();
    return body.isEmpty ? 'DM本文は未選択です' : body;
  }
}

class SendQueueVm extends ChangeNotifier {
  SendQueueVm({
    required String queueId,
    required LoadSendQueue loadSendQueue,
    required LoadSendQueueItems loadSendQueueItems,
    required LoadTemplates loadTemplates,
    required LoadScoutSettings loadScoutSettings,
    required DeleteSendQueue deleteSendQueue,
    required MarkAsManuallySent markAsManuallySent,
    required SendDirectMessage sendDirectMessage,
  }) : _queueId = queueId,
       _deleteSendQueue = deleteSendQueue,
       _markAsManuallySent = markAsManuallySent,
       _sendDirectMessage = sendDirectMessage {
    _queueSubscription = loadSendQueue(queueId).listen(
      (queue) {
        _state = _state.copyWith(
          queue: queue,
          isLoading: false,
          isProcessing: false,
        );
        notifyListeners();
      },
      onError: (_) {
        _state = _state.copyWith(
          isLoading: false,
          isProcessing: false,
          errorMessage: '送信キューの読み込みに失敗しました。',
        );
        notifyListeners();
      },
    );

    _itemsSubscription = loadSendQueueItems(queueId).listen(
      (items) {
        _state = _state.copyWith(
          items: items,
          selectedItemId: _validSelectedItemId(items),
          isLoading: false,
          isProcessing: false,
        );
        notifyListeners();
      },
      onError: (_) {
        _state = _state.copyWith(
          isLoading: false,
          isProcessing: false,
          errorMessage: '送信キュー明細の読み込みに失敗しました。',
        );
        notifyListeners();
      },
    );

    _templatesSubscription = loadTemplates().listen(
      (templates) {
        final activeTemplates = templates
            .where((template) => template.isActive)
            .toList();
        _state = _state.copyWith(
          templates: activeTemplates,
          selectedTemplateId: _validSelectedTemplateId(activeTemplates),
          isLoading: false,
          isProcessing: false,
        );
        notifyListeners();
      },
      onError: (_) {
        _state = _state.copyWith(
          isLoading: false,
          isProcessing: false,
          errorMessage: 'テンプレートの読み込みに失敗しました。',
        );
        notifyListeners();
      },
    );

    _settingsSubscription = loadScoutSettings().listen(
      (settings) {
        _state = _state.copyWith(
          settings: settings ?? ScoutSettings.defaults,
          isLoading: false,
          isProcessing: false,
        );
        notifyListeners();
      },
      onError: (_) {
        _state = _state.copyWith(
          isLoading: false,
          isProcessing: false,
          errorMessage: 'システム設定の読み込みに失敗しました。',
        );
        notifyListeners();
      },
    );
  }

  final String _queueId;
  final DeleteSendQueue _deleteSendQueue;
  final MarkAsManuallySent _markAsManuallySent;
  final SendDirectMessage _sendDirectMessage;
  late final StreamSubscription<SendQueue?> _queueSubscription;
  late final StreamSubscription<List<SendQueueItem>> _itemsSubscription;
  late final StreamSubscription<List<DmTemplate>> _templatesSubscription;
  late final StreamSubscription<ScoutSettings?> _settingsSubscription;

  SendQueueState _state = const SendQueueState();

  SendQueueState get state => _state;

  void selectItem(String itemId) {
    _state = _state.copyWith(
      selectedItemId: itemId,
      isLoading: false,
      isProcessing: false,
    );
    notifyListeners();
  }

  void selectTemplate(String templateId) {
    _state = _state.copyWith(
      selectedTemplateId: templateId,
      isLoading: false,
      isProcessing: false,
    );
    notifyListeners();
  }

  Future<bool> deleteQueue() async {
    _state = _state.copyWith(isLoading: false, isProcessing: true);
    notifyListeners();

    try {
      await _deleteSendQueue(_queueId);
      _state = _state.copyWith(
        isLoading: false,
        isProcessing: false,
        noticeMessage: '送信キューを削除しました。',
      );
      notifyListeners();
      return true;
    } on AppError catch (error) {
      _state = _state.copyWith(
        isLoading: false,
        isProcessing: false,
        errorMessage: error.message,
      );
      notifyListeners();
      return false;
    } catch (_) {
      _state = _state.copyWith(
        isLoading: false,
        isProcessing: false,
        errorMessage: '送信キューの削除に失敗しました。',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> markSelectedAsManuallySent() async {
    final item = _state.selectedItem;
    final template = _state.selectedTemplate;
    final messageBody = _state.messageBody.trim();

    if (item == null || template == null || messageBody.isEmpty) {
      _state = _state.copyWith(
        isLoading: false,
        isProcessing: false,
        errorMessage: '送信対象とテンプレートを選択してください。',
      );
      notifyListeners();
      return false;
    }

    _state = _state.copyWith(isLoading: false, isProcessing: true);
    notifyListeners();

    try {
      await _markAsManuallySent(
        queueId: _queueId,
        itemId: item.itemId,
        templateId: template.templateId,
        messageBody: messageBody,
      );
      _state = _state.copyWith(
        clearSelectedItem: true,
        isLoading: false,
        isProcessing: false,
        noticeMessage: '手動送信済みとして登録しました。',
      );
      notifyListeners();
      return true;
    } on AppError catch (error) {
      _state = _state.copyWith(
        isLoading: false,
        isProcessing: false,
        errorMessage: error.message,
      );
      notifyListeners();
      return false;
    } catch (_) {
      _state = _state.copyWith(
        isLoading: false,
        isProcessing: false,
        errorMessage: '手動送信済み登録に失敗しました。',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendSelectedByApi() async {
    final item = _state.selectedItem;
    final template = _state.selectedTemplate;
    final messageBody = _state.messageBody.trim();

    if (!_state.settings.apiDmEnabled) {
      _state = _state.copyWith(
        isLoading: false,
        isProcessing: false,
        errorMessage: 'X API DM送信が無効です。',
      );
      notifyListeners();
      return false;
    }

    if (item == null || template == null || messageBody.isEmpty) {
      _state = _state.copyWith(
        isLoading: false,
        isProcessing: false,
        errorMessage: '送信対象とテンプレートを選択してください。',
      );
      notifyListeners();
      return false;
    }

    _state = _state.copyWith(isLoading: false, isProcessing: true);
    notifyListeners();

    try {
      await _sendDirectMessage(
        queueId: _queueId,
        itemId: item.itemId,
        templateId: template.templateId,
        messageBody: messageBody,
      );
      _state = _state.copyWith(
        clearSelectedItem: true,
        isLoading: false,
        isProcessing: false,
        noticeMessage: 'X APIでDMを送信しました。',
      );
      notifyListeners();
      return true;
    } on AppError catch (error) {
      _state = _state.copyWith(
        isLoading: false,
        isProcessing: false,
        errorMessage: error.message,
      );
      notifyListeners();
      return false;
    } catch (_) {
      _state = _state.copyWith(
        isLoading: false,
        isProcessing: false,
        errorMessage: 'X API DM送信に失敗しました。',
      );
      notifyListeners();
      return false;
    }
  }

  String? _validSelectedItemId(List<SendQueueItem> items) {
    final selectedItemId = _state.selectedItemId;
    final hasSelectedItem =
        selectedItemId != null &&
        items.any((item) => item.itemId == selectedItemId && item.isSendable);
    if (hasSelectedItem) {
      return selectedItemId;
    }
    return items.where((item) => item.isSendable).firstOrNull?.itemId;
  }

  String? _validSelectedTemplateId(List<DmTemplate> templates) {
    final selectedTemplateId = _state.selectedTemplateId;
    final hasSelectedTemplate =
        selectedTemplateId != null &&
        templates.any((template) => template.templateId == selectedTemplateId);
    if (hasSelectedTemplate) {
      return selectedTemplateId;
    }
    return templates.firstOrNull?.templateId;
  }

  @override
  void dispose() {
    _queueSubscription.cancel();
    _itemsSubscription.cancel();
    _templatesSubscription.cancel();
    _settingsSubscription.cancel();
    super.dispose();
  }
}
