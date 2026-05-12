import 'package:flutter/material.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../core/ui/widgets/app_scaffold.dart';
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
                  FilledButton(
                    onPressed: state.isCreatingQueue ? null : _createQueue,
                    child: Text(
                      state.isCreatingQueue
                          ? '作成中'
                          : '送信キューに追加 (${state.selectedCandidateIds.length})',
                    ),
                  ),
                  Text('送信可能な候補のみ選択できます。'),
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
