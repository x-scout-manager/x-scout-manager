import 'package:flutter/material.dart';

import '../../../../core/ui/widgets/app_scaffold.dart';

class ExclusionKeywordSettingPage extends StatelessWidget {
  const ExclusionKeywordSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: '除外キーワード設定',
      body: Center(child: Text('除外キーワード設定')),
    );
  }
}
