import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:x_scout_manager/features/candidates/model/candidate.dart';
import 'package:x_scout_manager/features/candidates/model/candidate_status.dart';
import 'package:x_scout_manager/features/candidates/view/widgets/candidate_table.dart';

void main() {
  testWidgets('画面外の候補行を初期表示時に構築しない', (tester) async {
    final candidates = List.generate(
      100,
      (index) => Candidate(
        candidateId: 'candidate-$index',
        xUserId: 'candidate-$index',
        username: 'candidate-$index',
        displayName: '候補 $index',
        sourceTags: const ['#test'],
        status: CandidateStatus.candidate,
        isExcluded: false,
        isSent: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              CandidateTable(
                candidates: candidates,
                selectedCandidateIds: const {},
                onSelectionChanged: (_, _) {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('@candidate-0'), findsOneWidget);
    expect(find.text('@candidate-99'), findsNothing);
  });
}
