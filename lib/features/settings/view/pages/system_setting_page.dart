import 'package:flutter/material.dart';

import '../../../../app/di/providers.dart';
import '../../../../core/ui/widgets/app_scaffold.dart';
import '../../vm/system_setting_vm.dart';
import '../widgets/system_setting_body.dart';

class SystemSettingPage extends StatelessWidget {
  const SystemSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = AppProviders.of(context);
    return AppScaffold(
      title: 'システム設定',
      body: SystemSettingBody(
        vm: SystemSettingVm(
          dependencies.loadScoutSettings,
          dependencies.saveScoutSettings,
        ),
      ),
    );
  }
}
