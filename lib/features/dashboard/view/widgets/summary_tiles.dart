import 'package:flutter/material.dart';

import '../../model/dashboard_summary.dart';

class SummaryTiles extends StatelessWidget {
  const SummaryTiles({required this.summary, super.key});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _SummaryTile(label: '候補', value: summary.candidateCount.toString()),
        _SummaryTile(
          label: '未送信候補',
          value: summary.unsentCandidateCount.toString(),
        ),
        _SummaryTile(label: '送信済み', value: summary.sentCount.toString()),
        _SummaryTile(label: '除外', value: summary.excludedCount.toString()),
        _SummaryTile(
          label: '進行中キュー',
          value: summary.activeQueueCount.toString(),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
      ),
    );
  }
}
