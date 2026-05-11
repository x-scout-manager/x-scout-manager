import 'package:flutter/material.dart';

import '../../../../core/ui/widgets/app_scaffold.dart';

class CandidateDetailPage extends StatelessWidget {
  const CandidateDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: '候補詳細',
      body: Center(child: Text('候補詳細')),
    );
  }
}
