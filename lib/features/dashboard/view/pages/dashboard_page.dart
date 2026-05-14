import 'package:flutter/material.dart';

import '../../../../app/di/providers.dart';
import '../../../../core/ui/widgets/app_scaffold.dart';
import '../../vm/dashboard_vm.dart';
import '../widgets/summary_tiles.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = AppProviders.of(context);
    return AppScaffold(
      title: 'ダッシュボード',
      body: _DashboardBody(vm: DashboardVm(dependencies.loadDashboardSummary)),
    );
  }
}

class _DashboardBody extends StatefulWidget {
  const _DashboardBody({required this.vm});

  final DashboardVm vm;

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
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
        if (state.isLoading && state.summary == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.errorMessage != null && state.summary == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.errorMessage!),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: widget.vm.load,
                  child: const Text('再読み込み'),
                ),
              ],
            ),
          );
        }
        final summary = state.summary;
        if (summary == null) {
          return const Center(child: Text('表示できる集計データがありません。'));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.isLoading) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
              ],
              SummaryTiles(summary: summary),
            ],
          ),
        );
      },
    );
  }
}
