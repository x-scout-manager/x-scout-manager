import 'package:flutter/material.dart';

import '../../../../core/ui/widgets/app_scaffold.dart';
import '../widgets/summary_tiles.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'ダッシュボード',
      body: Padding(
        padding: EdgeInsets.all(24),
        child: SummaryTiles(),
      ),
    );
  }
}
