import 'package:flutter/material.dart';

import '../../../../app/di/providers.dart';
import '../../../../core/ui/widgets/app_scaffold.dart';
import '../../vm/exclusion_keyword_vm.dart';
import '../widgets/exclusion_keyword_body.dart';

class ExclusionKeywordSettingPage extends StatefulWidget {
  const ExclusionKeywordSettingPage({super.key});

  @override
  State<ExclusionKeywordSettingPage> createState() =>
      _ExclusionKeywordSettingPageState();
}

class _ExclusionKeywordSettingPageState
    extends State<ExclusionKeywordSettingPage> {
  late final ExclusionKeywordVm _vm;

  @override
  void initState() {
    super.initState();
    final dependencies = AppProviders.read(context);
    _vm = ExclusionKeywordVm(
      dependencies.exclusionRepository,
      dependencies.saveExclusionKeywords,
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
      title: '除外キーワード設定',
      body: ExclusionKeywordBody(vm: _vm),
    );
  }
}
