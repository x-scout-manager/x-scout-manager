import 'package:flutter/material.dart';

import '../../../../core/ui/widgets/app_scaffold.dart';

class SystemSettingPage extends StatelessWidget {
  const SystemSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'システム設定',
      body: Center(child: Text('システム設定')),
    );
  }
}
