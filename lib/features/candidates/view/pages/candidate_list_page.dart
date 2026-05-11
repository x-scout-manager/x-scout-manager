import 'package:flutter/material.dart';

import '../../../../core/ui/widgets/app_scaffold.dart';
import '../widgets/candidate_table.dart';

class CandidateListPage extends StatelessWidget {
  const CandidateListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: '候補一覧',
      body: Padding(
        padding: EdgeInsets.all(24),
        child: CandidateTable(),
      ),
    );
  }
}
