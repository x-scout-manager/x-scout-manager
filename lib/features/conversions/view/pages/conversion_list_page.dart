import 'package:flutter/material.dart';

import '../../../../core/ui/widgets/app_scaffold.dart';

class ConversionListPage extends StatelessWidget {
  const ConversionListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: '成果報告管理',
      body: Center(child: Text('成果報告管理')),
    );
  }
}
