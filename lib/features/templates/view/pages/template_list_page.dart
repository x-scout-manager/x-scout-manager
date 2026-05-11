import 'package:flutter/material.dart';

import '../../../../core/ui/widgets/app_scaffold.dart';
import '../widgets/template_editor.dart';

class TemplateListPage extends StatelessWidget {
  const TemplateListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'テンプレート',
      body: Padding(
        padding: EdgeInsets.all(24),
        child: TemplateEditor(),
      ),
    );
  }
}
