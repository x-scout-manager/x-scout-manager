import 'package:flutter/material.dart';

import '../../../../core/ui/widgets/app_scaffold.dart';

class ExcludedAccountPage extends StatelessWidget {
  const ExcludedAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: '除外リスト',
      body: Center(child: Text('除外リスト')),
    );
  }
}
