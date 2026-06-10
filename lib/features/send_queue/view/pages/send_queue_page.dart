import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../core/ui/widgets/app_scaffold.dart';
import '../../model/send_queue.dart';
import '../../model/send_queue_item.dart';
import '../../vm/send_queue_list_vm.dart';
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
          : const _SendQueueListBody(),
    );
  }
}

class _SendQueueListBody extends StatefulWidget {
  const _SendQueueListBody();

  @override
  State<_SendQueueListBody> createState() => _SendQueueListBodyState();
}

class _SendQueueListBodyState extends State<_SendQueueListBody> {
  late final SendQueueListVm _vm;

  @override
  void initState() {
    super.initState();
    final dependencies = AppProviders.read(context);
    _vm = SendQueueListVm(dependencies.loadSendQueues);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final state = _vm.state;
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.errorMessage != null) {
          return Center(child: Text(state.errorMessage!));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: state.queues.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _SendQueueListHeader(
                state: state,
                onShowCompletedChanged: _vm.setShowCompletedQueues,
              );
            }
            return _SendQueueCard(queue: state.queues[index - 1]);
          },
        );
      },
    );
  }
}

class _SendQueueListHeader extends StatelessWidget {
  const _SendQueueListHeader({
    required this.state,
    required this.onShowCompletedChanged,
  });

  final SendQueueListState state;
  final ValueChanged<bool> onShowCompletedChanged;

  @override
  Widget build(BuildContext context) {
    final emptyMessage = state.hasHiddenCompletedQueues
        ? '未完了の送信キューはありません。完了済みを確認する場合は表示を切り替えてください。'
        : '送信キューはまだありません。候補一覧から作成してください。';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('完了したキューも表示'),
            value: state.showCompletedQueues,
            onChanged: onShowCompletedChanged,
          ),
        ),
        if (state.queues.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(emptyMessage),
          ),
      ],
    );
  }
}

class _SendQueueCard extends StatelessWidget {
  const _SendQueueCard({required this.queue});

  final SendQueue queue;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(queue.name ?? '送信キュー'),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _StatusChip(label: queue.statusLabel, isActive: queue.isActive),
              Text('送信済み ${queue.completedCount}/${queue.totalCount}'),
              Text('スキップ ${queue.skippedCount}'),
              Text('失敗 ${queue.failedCount}'),
              Text('作成 ${_formatDateTime(queue.createdAt)}'),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(
          context,
        ).pushReplacementNamed(RoutePaths.sendQueue, arguments: queue.queueId),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.isActive});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primaryContainer
            : colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSecondaryContainer,
          ),
        ),
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
      loadScoutSettings: dependencies.loadScoutSettings,
      deleteSendQueue: dependencies.deleteSendQueue,
      markAsManuallySent: dependencies.markAsManuallySent,
      sendDirectMessage: dependencies.sendDirectMessage,
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

  Future<void> _sendByApi(String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('X APIでDM送信'),
          content: Text('@$username へDMを1件送信します。送信後は送信履歴に保存されます。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('送信'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    final succeeded = await _vm.sendSelectedByApi();
    if (!mounted || !succeeded) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('X APIでDMを送信しました。')));
  }

  Future<void> _deleteQueue() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('送信キューを削除'),
          content: const Text('この送信キューを一覧から削除します。送信履歴と候補データは削除されません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    final succeeded = await _vm.deleteQueue();
    if (!mounted || !succeeded) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('送信キューを削除しました。')));
    Navigator.of(context).pushReplacementNamed(RoutePaths.sendQueue);
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
        final messagePreview = state.messagePreview;

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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(queue.name ?? '送信キュー')),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: state.isProcessing
                              ? null
                              : () => Navigator.of(
                                  context,
                                ).pushReplacementNamed(RoutePaths.sendQueue),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('一覧へ戻る'),
                        ),
                        OutlinedButton.icon(
                          onPressed: state.isProcessing ? null : _deleteQueue,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('キュー削除'),
                        ),
                      ],
                    ),
                  ],
                ),
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
                MessagePreview(message: messagePreview),
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
                              !state.settings.apiDmEnabled ||
                              selectedItem == null ||
                              selectedTemplate == null ||
                              messageBody.isEmpty
                          ? null
                          : () => _sendByApi(selectedItem.username),
                      icon: const Icon(Icons.send_outlined),
                      label: Text(state.isProcessing ? '送信中' : 'APIでDM送信'),
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
                if (!state.settings.apiDmEnabled) ...[
                  const SizedBox(height: 12),
                  const Text('X API DM送信はシステム設定で無効です。'),
                ],
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
    final sendableItems = items.where((item) => item.isSendable).toList();
    if (sendableItems.isEmpty) {
      return const Text('未送信の候補はありません。');
    }

    return DropdownButtonFormField<String>(
      key: ValueKey('item-$selectedItemId-${sendableItems.length}'),
      initialValue: selectedItemId,
      decoration: const InputDecoration(labelText: '送信対象'),
      items: sendableItems
          .map(
            (item) => DropdownMenuItem(
              value: item.itemId,
              child: Text(
                item.status == 'failed'
                    ? '@${item.username}（失敗）'
                    : '@${item.username}',
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return '-';
  }

  String twoDigits(int number) => number.toString().padLeft(2, '0');
  final local = value.toLocal();
  return '${local.year}/${twoDigits(local.month)}/${twoDigits(local.day)} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}
