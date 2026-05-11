import 'package:flutter/material.dart';

import '../../../../core/ui/widgets/app_scaffold.dart';

class TagSettingPage extends StatelessWidget {
  const TagSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'タグ設定',
      body: Center(child: Text('タグ設定')),
    );
  }
}
