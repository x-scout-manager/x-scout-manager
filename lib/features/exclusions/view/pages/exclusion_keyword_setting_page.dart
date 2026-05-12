import 'package:flutter/material.dart';

import '../../../../app/di/providers.dart';
import '../../../../core/ui/widgets/app_scaffold.dart';
import '../../vm/exclusion_keyword_vm.dart';
import '../widgets/exclusion_keyword_body.dart';

class ExclusionKeywordSettingPage extends StatelessWidget {
  const ExclusionKeywordSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = AppProviders.of(context);
    return AppScaffold(
      title: '除外キーワード設定',
      body: ExclusionKeywordBody(
        vm: ExclusionKeywordVm(
          dependencies.exclusionRepository,
          dependencies.saveExclusionKeywords,
        ),
      ),
    );
  }
}
