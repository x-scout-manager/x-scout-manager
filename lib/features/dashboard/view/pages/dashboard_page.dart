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
              const _DashboardHeader(),
              const SizedBox(height: 18),
              SummaryTiles(summary: summary),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF23265F), Color(0xFF5B5FEF), Color(0xFF19B8D8)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B5FEF).withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Creator Scout Operations',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: const Color(0xFFDDE8FF),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '配信者候補の発掘から送信管理までを一元管理',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
