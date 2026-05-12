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
      return const Center(child: Text('候補データは未取得です'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('選択')),
          DataColumn(label: Text('ユーザー名')),
          DataColumn(label: Text('表示名')),
          DataColumn(label: Text('ステータス')),
          DataColumn(label: Text('タグ')),
          DataColumn(label: Text('送信可否')),
          DataColumn(label: Text('操作')),
        ],
        rows: candidates.map((candidate) {
          return DataRow(
            cells: [
              DataCell(
                Checkbox(
                  value: selectedCandidateIds.contains(candidate.candidateId),
                  onChanged: candidate.canSend
                      ? (selected) {
                          onSelectionChanged(candidate, selected == true);
                        }
                      : null,
                ),
              ),
              DataCell(Text('@${candidate.username}')),
              DataCell(Text(candidate.displayName ?? '-')),
              DataCell(CandidateStatusBadge(status: candidate.status)),
              DataCell(Text(candidate.sourceTags.join(', '))),
              DataCell(Text(candidate.canSend ? '可' : '不可')),
              DataCell(
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamed(
                    RoutePaths.candidateDetail,
                    arguments: candidate.candidateId,
                  ),
                  child: const Text('詳細'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
