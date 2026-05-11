import 'package:flutter/material.dart';

import '../../../../core/ui/widgets/app_scaffold.dart';

class SendHistoryPage extends StatelessWidget {
  const SendHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: '送信履歴',
      body: Center(child: Text('送信履歴')),
    );
  }
}
