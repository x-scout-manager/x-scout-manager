import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/di/providers.dart';
import '../../../../core/ui/widgets/app_scaffold.dart';
import '../../model/send_queue_item.dart';
import '../../vm/send_queue_vm.dart';
import '../widgets/message_preview.dart';
import '../widgets/queue_progress.dart';

class SendQueuePage extends StatelessWidget {
  const SendQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final queueId = ModalRoute.of(context)?.settings.arguments;
    return AppScaffold(
      title: '送信キュー',
      body: queueId is String && queueId.isNotEmpty
          ? _SendQueueBody(queueId: queueId)
          : const Padding(
              padding: EdgeInsets.all(24),
              child: Text('候補一覧から送信キューを作成してください。'),
            ),
    );
  }
}

class _SendQueueBody extends StatefulWidget {
  const _SendQueueBody({required this.queueId});

  final String queueId;

  @override
  State<_SendQueueBody> createState() => _SendQueueBodyState();
}

class _SendQueueBodyState extends State<_SendQueueBody> {
  late final SendQueueVm _vm;

  @override
  void initState() {
    super.initState();
    final dependencies = AppProviders.read(context);
    _vm = SendQueueVm(
      queueId: widget.queueId,
      loadSendQueue: dependencies.loadSendQueue,
      loadSendQueueItems: dependencies.loadSendQueueItems,
      loadTemplates: dependencies.loadTemplates,
      markAsManuallySent: dependencies.markAsManuallySent,
    );
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _copyMessage(String message) async {
    await Clipboard.setData(ClipboardData(text: message));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('本文をコピーしました。')));
  }

  Future<void> _markAsSent() async {
    final succeeded = await _vm.markSelectedAsManuallySent();
    if (!mounted || !succeeded) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('送信履歴に登録しました。')));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final state = _vm.state;
        final queue = state.queue;
        final selectedItem = state.selectedItem;
        final selectedTemplate = state.selectedTemplate;
        final messageBody = state.messageBody;

        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (queue == null) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('送信キューが見つかりません。'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(queue.name ?? '送信キュー'),
                const SizedBox(height: 8),
                Text('キューID: ${queue.queueId}'),
                const SizedBox(height: 16),
                QueueProgress(
                  current: queue.completedCount,
                  total: queue.totalCount,
                ),
                const SizedBox(height: 24),
                _QueueItemSelector(
                  items: state.items,
                  selectedItemId: selectedItem?.itemId,
                  onChanged: (itemId) {
                    if (itemId != null) {
                      _vm.selectItem(itemId);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey(
                    'template-${selectedTemplate?.templateId}-${state.templates.length}',
                  ),
                  initialValue: selectedTemplate?.templateId,
                  decoration: const InputDecoration(labelText: 'テンプレート'),
                  items: state.templates
                      .map(
                        (template) => DropdownMenuItem(
                          value: template.templateId,
                          child: Text(template.name),
                        ),
                      )
                      .toList(),
                  onChanged: state.isProcessing
                      ? null
                      : (templateId) {
                          if (templateId != null) {
                            _vm.selectTemplate(templateId);
                          }
                        },
                ),
                const SizedBox(height: 24),
                MessagePreview(
                  message: messageBody.isEmpty ? 'DM本文は未選択です' : messageBody,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: messageBody.isEmpty
                          ? null
                          : () => _copyMessage(messageBody),
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('本文コピー'),
                    ),
                    FilledButton.icon(
                      onPressed:
                          state.isProcessing ||
                              selectedItem == null ||
                              selectedTemplate == null ||
                              messageBody.isEmpty
                          ? null
                          : _markAsSent,
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(state.isProcessing ? '登録中' : '手動送信済みにする'),
                    ),
                  ],
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (state.noticeMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(state.noticeMessage!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QueueItemSelector extends StatelessWidget {
  const _QueueItemSelector({
    required this.items,
    required this.selectedItemId,
    required this.onChanged,
  });

  final List<SendQueueItem> items;
  final String? selectedItemId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final pendingItems = items.where((item) => item.isPending).toList();
    if (pendingItems.isEmpty) {
      return const Text('未送信の候補はありません。');
    }

    return DropdownButtonFormField<String>(
      key: ValueKey('item-$selectedItemId-${pendingItems.length}'),
      initialValue: selectedItemId,
      decoration: const InputDecoration(labelText: '送信対象'),
      items: pendingItems
          .map(
            (item) => DropdownMenuItem(
              value: item.itemId,
              child: Text('@${item.username}'),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
