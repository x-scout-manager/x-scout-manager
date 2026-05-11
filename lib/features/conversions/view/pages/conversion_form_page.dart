import 'package:flutter/material.dart';

import '../../../../core/ui/widgets/app_scaffold.dart';

class ConversionFormPage extends StatelessWidget {
  const ConversionFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: '成果登録',
      body: Center(child: Text('成果登録')),
    );
  }
}
