import 'package:flutter/material.dart';

import '../../../../app/di/providers.dart';
import '../../../../core/ui/widgets/app_scaffold.dart';
import '../../vm/tag_setting_vm.dart';
import '../widgets/tag_setting_body.dart';

class TagSettingPage extends StatelessWidget {
  const TagSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = AppProviders.of(context);
    return AppScaffold(
      title: 'タグ設定',
      body: TagSettingBody(
        vm: TagSettingVm(dependencies.loadScoutSettings, dependencies.saveTags),
      ),
    );
  }
}
