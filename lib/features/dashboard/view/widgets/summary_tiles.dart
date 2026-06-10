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
        _SummaryTile(
          label: '候補',
          value: summary.candidateCount.toString(),
          color: const Color(0xFF5B5FEF),
          icon: Icons.groups_outlined,
        ),
        _SummaryTile(
          label: '未送信候補',
          value: summary.unsentCandidateCount.toString(),
          color: const Color(0xFF13A9C7),
          icon: Icons.campaign_outlined,
        ),
        _SummaryTile(
          label: '送信済み',
          value: summary.sentCount.toString(),
          color: const Color(0xFF2F8F6B),
          icon: Icons.mark_email_read_outlined,
        ),
        _SummaryTile(
          label: '除外',
          value: summary.excludedCount.toString(),
          color: const Color(0xFFD25B69),
          icon: Icons.block_outlined,
        ),
        _SummaryTile(
          label: '進行中キュー',
          value: summary.activeQueueCount.toString(),
          color: const Color(0xFF8A5CF6),
          icon: Icons.queue_outlined,
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 196,
      child: Card(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.94),
                color.withValues(alpha: 0.08),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const Spacer(),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF191A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5E627A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
