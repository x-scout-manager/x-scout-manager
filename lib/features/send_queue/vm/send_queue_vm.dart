import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../templates/model/dm_template.dart';
import '../../templates/usecase/load_templates.dart';
import '../model/send_queue.dart';
import '../model/send_queue_item.dart';
import '../usecase/load_send_queue.dart';
import '../usecase/load_send_queue_items.dart';
import '../usecase/mark_as_manually_sent.dart';

class SendQueueState {
  const SendQueueState({
    this.queue,
    this.items = const [],
    this.templates = const [],
    this.selectedTemplateId,
    this.selectedItemId,
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
  final bool isLoading;
  final bool isProcessing;
  final String? errorMessage;
  final String? noticeMessage;

  SendQueueItem? get selectedItem {
    for (final item in items) {
      if (item.itemId == selectedItemId) {
        return item;
      }
    }
    return items.where((item) => item.isPending).firstOrNull;
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
}

class SendQueueVm extends ChangeNotifier {
  SendQueueVm({
    required String queueId,
    required LoadSendQueue loadSendQueue,
    required LoadSendQueueItems loadSendQueueItems,
    required LoadTemplates loadTemplates,
    required MarkAsManuallySent markAsManuallySent,
  }) : _queueId = queueId,
       _markAsManuallySent = markAsManuallySent {
    _queueSubscription = loadSendQueue(queueId).listen(
      (queue) {
        _state = SendQueueState(
          queue: queue,
          items: _state.items,
          templates: _state.templates,
          selectedTemplateId: _state.selectedTemplateId,
          selectedItemId: _state.selectedItemId,
          isLoading: false,
        );
        notifyListeners();
      },
      onError: (_) {
        _state = SendQueueState(
          items: _state.items,
          templates: _state.templates,
          selectedTemplateId: _state.selectedTemplateId,
          selectedItemId: _state.selectedItemId,
          isLoading: false,
          errorMessage: '送信キューの読み込みに失敗しました。',
        );
        notifyListeners();
      },
    );

    _itemsSubscription = loadSendQueueItems(queueId).listen(
      (items) {
        _state = SendQueueState(
          queue: _state.queue,
          items: items,
          templates: _state.templates,
          selectedTemplateId: _state.selectedTemplateId,
          selectedItemId: _validSelectedItemId(items),
          isLoading: false,
        );
        notifyListeners();
      },
      onError: (_) {
        _state = SendQueueState(
          queue: _state.queue,
          templates: _state.templates,
          selectedTemplateId: _state.selectedTemplateId,
          selectedItemId: _state.selectedItemId,
          isLoading: false,
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
        _state = SendQueueState(
          queue: _state.queue,
          items: _state.items,
          templates: activeTemplates,
          selectedTemplateId: _validSelectedTemplateId(activeTemplates),
          selectedItemId: _state.selectedItemId,
          isLoading: false,
        );
        notifyListeners();
      },
      onError: (_) {
        _state = SendQueueState(
          queue: _state.queue,
          items: _state.items,
          selectedItemId: _state.selectedItemId,
          isLoading: false,
          errorMessage: 'テンプレートの読み込みに失敗しました。',
        );
        notifyListeners();
      },
    );
  }

  final String _queueId;
  final MarkAsManuallySent _markAsManuallySent;
  late final StreamSubscription<SendQueue?> _queueSubscription;
  late final StreamSubscription<List<SendQueueItem>> _itemsSubscription;
  late final StreamSubscription<List<DmTemplate>> _templatesSubscription;

  SendQueueState _state = const SendQueueState();

  SendQueueState get state => _state;

  void selectItem(String itemId) {
    _state = SendQueueState(
      queue: _state.queue,
      items: _state.items,
      templates: _state.templates,
      selectedTemplateId: _state.selectedTemplateId,
      selectedItemId: itemId,
      isLoading: false,
    );
    notifyListeners();
  }

  void selectTemplate(String templateId) {
    _state = SendQueueState(
      queue: _state.queue,
      items: _state.items,
      templates: _state.templates,
      selectedTemplateId: templateId,
      selectedItemId: _state.selectedItemId,
      isLoading: false,
    );
    notifyListeners();
  }

  Future<bool> markSelectedAsManuallySent() async {
    final item = _state.selectedItem;
    final template = _state.selectedTemplate;
    final messageBody = _state.messageBody.trim();

    if (item == null || template == null || messageBody.isEmpty) {
      _state = SendQueueState(
        queue: _state.queue,
        items: _state.items,
        templates: _state.templates,
        selectedTemplateId: _state.selectedTemplateId,
        selectedItemId: _state.selectedItemId,
        isLoading: false,
        errorMessage: '送信対象とテンプレートを選択してください。',
      );
      notifyListeners();
      return false;
    }

    _state = SendQueueState(
      queue: _state.queue,
      items: _state.items,
      templates: _state.templates,
      selectedTemplateId: _state.selectedTemplateId,
      selectedItemId: _state.selectedItemId,
      isLoading: false,
      isProcessing: true,
    );
    notifyListeners();

    try {
      await _markAsManuallySent(
        queueId: _queueId,
        itemId: item.itemId,
        templateId: template.templateId,
        messageBody: messageBody,
      );
      _state = SendQueueState(
        queue: _state.queue,
        items: _state.items,
        templates: _state.templates,
        selectedTemplateId: _state.selectedTemplateId,
        selectedItemId: null,
        isLoading: false,
        noticeMessage: '手動送信済みとして登録しました。',
      );
      notifyListeners();
      return true;
    } on AppError catch (error) {
      _state = SendQueueState(
        queue: _state.queue,
        items: _state.items,
        templates: _state.templates,
        selectedTemplateId: _state.selectedTemplateId,
        selectedItemId: _state.selectedItemId,
        isLoading: false,
        errorMessage: error.message,
      );
      notifyListeners();
      return false;
    } catch (_) {
      _state = SendQueueState(
        queue: _state.queue,
        items: _state.items,
        templates: _state.templates,
        selectedTemplateId: _state.selectedTemplateId,
        selectedItemId: _state.selectedItemId,
        isLoading: false,
        errorMessage: '手動送信済み登録に失敗しました。',
      );
      notifyListeners();
      return false;
    }
  }

  String? _validSelectedItemId(List<SendQueueItem> items) {
    final selectedItemId = _state.selectedItemId;
    final hasSelectedItem =
        selectedItemId != null &&
        items.any((item) => item.itemId == selectedItemId && item.isPending);
    if (hasSelectedItem) {
      return selectedItemId;
    }
    return items.where((item) => item.isPending).firstOrNull?.itemId;
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
    super.dispose();
  }
}
