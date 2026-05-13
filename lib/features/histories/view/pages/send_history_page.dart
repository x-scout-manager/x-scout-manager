import 'package:flutter/material.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../core/ui/widgets/app_scaffold.dart';
import '../../model/send_history.dart';
import '../../vm/send_history_vm.dart';

class SendHistoryPage extends StatelessWidget {
  const SendHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = AppProviders.of(context);
    return AppScaffold(
      title: '送信履歴',
      body: _SendHistoryBody(vm: SendHistoryVm(dependencies.loadSendHistories)),
    );
  }
}

class _SendHistoryBody extends StatefulWidget {
  const _SendHistoryBody({required this.vm});

  final SendHistoryVm vm;

  @override
  State<_SendHistoryBody> createState() => _SendHistoryBodyState();
}

class _SendHistoryBodyState extends State<_SendHistoryBody> {
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
        if (state.errorMessage != null) {
          return Center(child: Text(state.errorMessage!));
        }
        if (state.histories.isEmpty) {
          return const Center(child: Text('送信履歴はまだありません。'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: state.histories.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _SendHistoryCard(history: state.histories[index]);
          },
        );
      },
    );
  }
}

class _SendHistoryCard extends StatelessWidget {
  const _SendHistoryCard({required this.history});

  final SendHistory history;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  history.displayUserName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _MethodBadge(label: history.sendMethodLabel),
                Text(_formatDateTime(history.sentAt)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              history.templateName?.isNotEmpty == true
                  ? 'テンプレート: ${history.templateName}'
                  : 'テンプレート: -',
            ),
            const SizedBox(height: 8),
            SelectableText(history.messageBodySnapshot),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Text('XユーザーID: ${history.xUserId}'),
                Text('履歴ID: ${history.historyId}'),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: history.candidateId.isEmpty
                  ? null
                  : () => Navigator.of(context).pushNamed(
                      RoutePaths.candidateDetail,
                      arguments: history.candidateId,
                    ),
              icon: const Icon(Icons.person_search_outlined),
              label: const Text('候補詳細'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodBadge extends StatelessWidget {
  const _MethodBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(color: colorScheme.onSecondaryContainer),
        ),
      ),
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
