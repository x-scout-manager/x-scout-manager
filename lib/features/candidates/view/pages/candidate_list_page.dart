import 'package:flutter/material.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../core/ui/widgets/app_scaffold.dart';
import '../../../settings/model/scout_settings.dart';
import '../../model/candidate_sync_run.dart';
import '../../vm/candidate_list_vm.dart';
import '../widgets/candidate_table.dart';

class CandidateListPage extends StatelessWidget {
  const CandidateListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = AppProviders.of(context);
    return AppScaffold(
      title: '候補一覧',
      body: _CandidateListBody(
        vm: CandidateListVm(
          dependencies.loadCandidates,
          dependencies.createSendQueue,
          dependencies.syncCandidates,
          dependencies.loadCandidateSyncRuns,
          dependencies.revertCandidateSyncRun,
          dependencies.cleanupRevertedCandidates,
          dependencies.loadScoutSettings,
          dependencies.saveScoutSettings,
        ),
      ),
    );
  }
}

class _CandidateListBody extends StatefulWidget {
  const _CandidateListBody({required this.vm});

  final CandidateListVm vm;

  @override
  State<_CandidateListBody> createState() => _CandidateListBodyState();
}

class _CandidateListBodyState extends State<_CandidateListBody> {
  Future<void> _createQueue() async {
    final queueId = await widget.vm.createQueue();
    if (queueId == null || !mounted) {
      return;
    }
    Navigator.of(
      context,
    ).pushReplacementNamed(RoutePaths.sendQueue, arguments: queueId);
  }

  Future<void> _confirmRevert(CandidateSyncRun run) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('抽出を解除しますか'),
          content: const Text(
            'この抽出で作成・更新された候補を抽出前の状態へ戻します。送信済み、送信キュー投入済み、後続抽出で更新済みの候補は解除対象からスキップされます。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('解除する'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await widget.vm.revertSyncRun(run.runId);
    }
  }

  Future<void> _confirmCleanupRevertedCandidates() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('解除済み候補を再掃除しますか'),
          content: const Text(
            'すべての抽出元が解除済みの未送信候補を再確認し、抽出前の状態へ戻します。送信履歴や有効な送信キューに紐づく候補はスキップされます。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('再掃除する'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await widget.vm.cleanupRevertedCandidates();
    }
  }

  @override
  void dispose() {
    widget.vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        final state = widget.vm.state;
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 260,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'タグ検索モード',
                        isDense: true,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<TagSearchMode>(
                          value: state.settings.tagSearchMode,
                          isDense: true,
                          isExpanded: true,
                          items: TagSearchMode.values
                              .map(
                                (mode) => DropdownMenuItem(
                                  value: mode,
                                  child: Text(mode.label),
                                ),
                              )
                              .toList(),
                          onChanged: state.isSavingSearchMode || state.isSyncing
                              ? null
                              : (mode) {
                                  if (mode != null) {
                                    widget.vm.changeTagSearchMode(mode);
                                  }
                                },
                        ),
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: state.isCreatingQueue ? null : _createQueue,
                    child: Text(
                      state.isCreatingQueue
                          ? '作成中'
                          : '送信キューに追加 (${state.selectedCandidateIds.length})',
                    ),
                  ),
                  OutlinedButton(
                    onPressed: state.isSyncing
                        ? null
                        : widget.vm.syncCandidates,
                    child: Text(state.isSyncing ? '抽出中' : 'X API候補抽出'),
                  ),
                  const Text('送信可能な候補のみ選択できます。'),
                ],
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (state.noticeMessage != null) ...[
                const SizedBox(height: 16),
                Text(state.noticeMessage!),
              ],
              if (state.syncRuns.isNotEmpty) ...[
                const SizedBox(height: 24),
                _SyncRunPanel(
                  runs: state.syncRuns,
                  isReverting: state.isRevertingSyncRun,
                  isCleaning: state.isCleaningRevertedCandidates,
                  onRevert: _confirmRevert,
                  onCleanup: _confirmCleanupRevertedCandidates,
                ),
              ],
              const SizedBox(height: 24),
              CandidateTable(
                candidates: state.candidates,
                selectedCandidateIds: state.selectedCandidateIds,
                onSelectionChanged: widget.vm.toggleSelection,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SyncRunPanel extends StatelessWidget {
  const _SyncRunPanel({
    required this.runs,
    required this.isReverting,
    required this.isCleaning,
    required this.onRevert,
    required this.onCleanup,
  });

  final List<CandidateSyncRun> runs;
  final bool isReverting;
  final bool isCleaning;
  final Future<void> Function(CandidateSyncRun run) onRevert;
  final VoidCallback onCleanup;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('最近の候補抽出', style: Theme.of(context).textTheme.titleMedium),
            OutlinedButton(
              onPressed: isReverting || isCleaning ? null : onCleanup,
              child: Text(isCleaning ? '再掃除中' : '解除済み候補を再掃除'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('実行日時')),
              DataColumn(label: Text('条件')),
              DataColumn(label: Text('件数')),
              DataColumn(label: Text('状態')),
              DataColumn(label: Text('操作')),
            ],
            rows: runs.map((run) {
              return DataRow(
                cells: [
                  DataCell(Text(_formatDateTime(run.createdAt))),
                  DataCell(
                    Text('${run.tagSearchModeLabel} / ${run.tags.join(', ')}'),
                  ),
                  DataCell(
                    Text(
                      '新規${run.createdCount} 更新${run.updatedCount} 除外${run.excludedCount}',
                    ),
                  ),
                  DataCell(Text(run.statusLabel)),
                  DataCell(
                    TextButton(
                      onPressed: run.canRevert && !isReverting
                          ? () => onRevert(run)
                          : null,
                      child: Text(isReverting ? '解除中' : '解除'),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return '-';
  }
  final local = value.toLocal();
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${local.year}/${twoDigits(local.month)}/${twoDigits(local.day)} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}
