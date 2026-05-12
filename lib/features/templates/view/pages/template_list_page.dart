import 'package:flutter/material.dart';

import '../../../../app/di/providers.dart';
import '../../../../core/ui/widgets/app_scaffold.dart';
import '../../vm/template_list_vm.dart';
import '../widgets/template_editor.dart';

class TemplateListPage extends StatelessWidget {
  const TemplateListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = AppProviders.of(context);
    return AppScaffold(
      title: 'テンプレート',
      body: TemplateEditor(
        vm: TemplateListVm(
          dependencies.loadTemplates,
          dependencies.saveTemplate,
        ),
      ),
    );
  }
}
