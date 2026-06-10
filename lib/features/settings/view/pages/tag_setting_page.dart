import 'package:flutter/material.dart';

import '../../../../app/di/providers.dart';
import '../../../../core/ui/widgets/app_scaffold.dart';
import '../../vm/tag_setting_vm.dart';
import '../widgets/tag_setting_body.dart';

class TagSettingPage extends StatefulWidget {
  const TagSettingPage({super.key});

  @override
  State<TagSettingPage> createState() => _TagSettingPageState();
}

class _TagSettingPageState extends State<TagSettingPage> {
  late final TagSettingVm _vm;

  @override
  void initState() {
    super.initState();
    final dependencies = AppProviders.read(context);
    _vm = TagSettingVm(dependencies.loadScoutSettings, dependencies.saveTags);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'タグ設定',
      body: TagSettingBody(vm: _vm),
    );
  }
}
