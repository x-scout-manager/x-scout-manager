import 'package:flutter/material.dart';

import '../../../../app/di/providers.dart';
import '../../../../core/ui/widgets/app_scaffold.dart';
import '../../vm/template_list_vm.dart';
import '../widgets/template_editor.dart';

class TemplateListPage extends StatefulWidget {
  const TemplateListPage({super.key});

  @override
  State<TemplateListPage> createState() => _TemplateListPageState();
}

class _TemplateListPageState extends State<TemplateListPage> {
  late final TemplateListVm _vm;

  @override
  void initState() {
    super.initState();
    final dependencies = AppProviders.read(context);
    _vm = TemplateListVm(
      dependencies.loadTemplates,
      dependencies.deleteTemplate,
      dependencies.saveTemplate,
    );
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'テンプレート',
      body: TemplateEditor(vm: _vm),
    );
  }
}
