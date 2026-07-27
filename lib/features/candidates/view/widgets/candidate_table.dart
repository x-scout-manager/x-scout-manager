import 'package:flutter/material.dart';

import '../../../../app/router/route_paths.dart';
import '../../model/candidate.dart';
import 'candidate_status_badge.dart';

class CandidateTable extends StatelessWidget {
  const CandidateTable({
    required this.candidates,
    required this.selectedCandidateIds,
    required this.onSelectionChanged,
    super.key,
  });

  final List<Candidate> candidates;
  final Set<String> selectedCandidateIds;
  final void Function(Candidate candidate, bool selected) onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: Text('候補データは未取得です')),
        ),
      );
    }

    return SliverList.separated(
      itemCount: candidates.length,
      itemBuilder: (context, index) {
        final candidate = candidates[index];
        return Card(
          key: ValueKey(candidate.candidateId),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: selectedCandidateIds.contains(candidate.candidateId),
                  onChanged: candidate.canSend
                      ? (selected) {
                          onSelectionChanged(candidate, selected == true);
                        }
                      : null,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            candidate.displayName ?? '-',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '@${candidate.username}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          CandidateStatusBadge(status: candidate.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Text(
                            candidate.sourceTags.isEmpty
                                ? 'タグ: -'
                                : 'タグ: ${candidate.sourceTags.join(', ')}',
                          ),
                          Text('送信: ${candidate.canSend ? '可' : '不可'}'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamed(
                    RoutePaths.candidateDetail,
                    arguments: candidate.candidateId,
                  ),
                  child: const Text('詳細'),
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 8),
    );
  }
}
