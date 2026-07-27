import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:x_scout_manager/core/errors/app_error.dart';
import 'package:x_scout_manager/features/send_queue/data/send_queue_functions_repository.dart';
import 'package:x_scout_manager/features/send_queue/data/send_queue_repository.dart';
import 'package:x_scout_manager/features/send_queue/model/send_queue.dart';
import 'package:x_scout_manager/features/send_queue/model/send_queue_item.dart';
import 'package:x_scout_manager/features/send_queue/usecase/delete_send_queue.dart';
import 'package:x_scout_manager/features/send_queue/usecase/load_send_queue.dart';
import 'package:x_scout_manager/features/send_queue/usecase/load_send_queue_items.dart';
import 'package:x_scout_manager/features/send_queue/usecase/mark_as_manually_sent.dart';
import 'package:x_scout_manager/features/send_queue/usecase/send_direct_message.dart';
import 'package:x_scout_manager/features/send_queue/vm/send_queue_vm.dart';
import 'package:x_scout_manager/features/settings/data/settings_repository.dart';
import 'package:x_scout_manager/features/settings/model/scout_settings.dart';
import 'package:x_scout_manager/features/settings/model/tag_setting.dart';
import 'package:x_scout_manager/features/settings/usecase/load_scout_settings.dart';
import 'package:x_scout_manager/features/templates/data/template_repository.dart';
import 'package:x_scout_manager/features/templates/model/dm_template.dart';
import 'package:x_scout_manager/features/templates/usecase/load_templates.dart';

void main() {
  test('API送信後に明細更新を受けて次の送信可能候補へ移る', () async {
    final queueRepository = _FakeSendQueueRepository();
    final templateRepository = _FakeTemplateRepository();
    final settingsRepository = _FakeSettingsRepository();
    final functionsRepository = _RecordingSendQueueFunctionsRepository();
    final vm = SendQueueVm(
      queueId: 'queue-1',
      loadSendQueue: LoadSendQueue(queueRepository),
      loadSendQueueItems: LoadSendQueueItems(queueRepository),
      loadTemplates: LoadTemplates(templateRepository),
      loadScoutSettings: LoadScoutSettings(settingsRepository),
      deleteSendQueue: DeleteSendQueue(functionsRepository),
      markAsManuallySent: MarkAsManuallySent(functionsRepository),
      sendDirectMessage: SendDirectMessage(functionsRepository),
    );
    addTearDown(() async {
      vm.dispose();
      await queueRepository.dispose();
      await templateRepository.dispose();
      await settingsRepository.dispose();
    });

    queueRepository.emitQueue(_queue());
    queueRepository.emitItems([
      _item('item-1', order: 0),
      _item('item-2', order: 1),
      _item('item-3', order: 2),
      _item('item-4', order: 3),
    ]);
    templateRepository.emitTemplates([
      const DmTemplate(
        templateId: 'template-1',
        name: 'テスト',
        body: '{{displayName}}さん、こんにちは。',
        isActive: true,
      ),
    ]);
    settingsRepository.emitSettings(
      ScoutSettings.defaults.copyWith(apiDmEnabled: true),
    );
    await Future<void>.delayed(Duration.zero);

    expect(vm.state.selectedItem?.itemId, 'item-1');

    final sent = await vm.sendSelectedByApi();

    expect(sent, isTrue);
    expect(functionsRepository.sentMessages.single.itemId, 'item-1');

    queueRepository.emitItems([
      _item('item-1', order: 0, status: 'sent'),
      _item('item-2', order: 1),
      _item('item-3', order: 2),
      _item('item-4', order: 3),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(vm.state.selectedItem?.itemId, 'item-2');
    expect(vm.state.messagePreview, 'item-2さん、こんにちは。');
  });

  test('API送信失敗後に失敗明細ではなく次の送信可能候補へ移る', () async {
    final queueRepository = _FakeSendQueueRepository();
    final templateRepository = _FakeTemplateRepository();
    final settingsRepository = _FakeSettingsRepository();
    final functionsRepository = _RecordingSendQueueFunctionsRepository()
      ..sendError = const AppError('送信先アカウントのDM受信設定により送信できません。');
    final vm = SendQueueVm(
      queueId: 'queue-1',
      loadSendQueue: LoadSendQueue(queueRepository),
      loadSendQueueItems: LoadSendQueueItems(queueRepository),
      loadTemplates: LoadTemplates(templateRepository),
      loadScoutSettings: LoadScoutSettings(settingsRepository),
      deleteSendQueue: DeleteSendQueue(functionsRepository),
      markAsManuallySent: MarkAsManuallySent(functionsRepository),
      sendDirectMessage: SendDirectMessage(functionsRepository),
    );
    addTearDown(() async {
      vm.dispose();
      await queueRepository.dispose();
      await templateRepository.dispose();
      await settingsRepository.dispose();
    });

    queueRepository.emitQueue(_queue());
    queueRepository.emitItems([
      _item('item-1', order: 0),
      _item('item-2', order: 1),
      _item('item-3', order: 2),
      _item('item-4', order: 3),
    ]);
    templateRepository.emitTemplates([
      const DmTemplate(
        templateId: 'template-1',
        name: 'テスト',
        body: '{{displayName}}さん、こんにちは。',
        isActive: true,
      ),
    ]);
    settingsRepository.emitSettings(
      ScoutSettings.defaults.copyWith(apiDmEnabled: true),
    );
    await Future<void>.delayed(Duration.zero);

    expect(vm.state.selectedItem?.itemId, 'item-1');

    final sent = await vm.sendSelectedByApi();

    expect(sent, isFalse);
    expect(vm.state.errorMessage, '送信先アカウントのDM受信設定により送信できません。');

    queueRepository.emitItems([
      _item('item-1', order: 0, status: 'failed'),
      _item('item-2', order: 1),
      _item('item-3', order: 2),
      _item('item-4', order: 3),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(vm.state.selectedItem?.itemId, 'item-2');
    expect(vm.state.messagePreview, 'item-2さん、こんにちは。');
  });
}

SendQueue _queue() {
  return const SendQueue(
    queueId: 'queue-1',
    status: 'active',
    currentIndex: 0,
    totalCount: 4,
    completedCount: 0,
    skippedCount: 0,
    failedCount: 0,
  );
}

SendQueueItem _item(
  String itemId, {
  required int order,
  String status = 'pending',
}) {
  return SendQueueItem(
    itemId: itemId,
    queueId: 'queue-1',
    candidateId: itemId,
    xUserId: itemId,
    username: itemId,
    displayName: itemId,
    status: status,
    order: order,
  );
}

class _FakeSendQueueRepository implements SendQueueRepository {
  final _queueController = StreamController<SendQueue?>.broadcast();
  final _itemsController = StreamController<List<SendQueueItem>>.broadcast();

  void emitQueue(SendQueue queue) {
    _queueController.add(queue);
  }

  void emitItems(List<SendQueueItem> items) {
    _itemsController.add(items);
  }

  Future<void> dispose() async {
    await _queueController.close();
    await _itemsController.close();
  }

  @override
  Future<SendQueue?> findQueue(String queueId) async {
    return null;
  }

  @override
  Stream<List<SendQueue>> watchQueues() {
    return const Stream.empty();
  }

  @override
  Stream<SendQueue?> watchQueue(String queueId) {
    return _queueController.stream;
  }

  @override
  Stream<List<SendQueueItem>> watchItems(String queueId) {
    return _itemsController.stream;
  }
}

class _FakeTemplateRepository implements TemplateRepository {
  final _controller = StreamController<List<DmTemplate>>.broadcast();

  void emitTemplates(List<DmTemplate> templates) {
    _controller.add(templates);
  }

  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Stream<List<DmTemplate>> watchTemplates() {
    return _controller.stream;
  }

  @override
  Future<void> saveTemplate(DmTemplate template) async {}

  @override
  Future<void> deleteTemplate(String templateId) async {}
}

class _FakeSettingsRepository implements SettingsRepository {
  final _controller = StreamController<ScoutSettings?>.broadcast();

  void emitSettings(ScoutSettings settings) {
    _controller.add(settings);
  }

  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Stream<ScoutSettings?> watchScoutSettings() {
    return _controller.stream;
  }

  @override
  Future<void> saveScoutSettings(ScoutSettings settings) async {}

  @override
  Future<void> saveTags(List<TagSetting> tags) async {}
}

class _RecordingSendQueueFunctionsRepository
    implements SendQueueFunctionsRepository {
  final sentMessages = <_SentMessage>[];
  AppError? sendError;

  @override
  Future<String> createSendQueue(List<String> candidateIds) async {
    return 'queue-id';
  }

  @override
  Future<void> deleteSendQueue(String queueId) async {}

  @override
  Future<void> markAsManuallySent({
    required String queueId,
    required String itemId,
    required String templateId,
    required String messageBody,
  }) async {}

  @override
  Future<void> sendDirectMessage({
    required String queueId,
    required String itemId,
    required String templateId,
    required String messageBody,
  }) async {
    final error = sendError;
    if (error != null) {
      throw error;
    }
    sentMessages.add(
      _SentMessage(
        queueId: queueId,
        itemId: itemId,
        templateId: templateId,
        messageBody: messageBody,
      ),
    );
  }
}

class _SentMessage {
  const _SentMessage({
    required this.queueId,
    required this.itemId,
    required this.templateId,
    required this.messageBody,
  });

  final String queueId;
  final String itemId;
  final String templateId;
  final String messageBody;
}
