import 'package:flutter/material.dart';

import '../../../../app/di/providers.dart';
import '../../../../core/ui/widgets/app_scaffold.dart';
import '../../vm/login_vm.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = AppProviders.of(context);
    return AppScaffold(
      title: 'ログイン',
      body: Center(child: LoginForm(vm: LoginVm(dependencies.signIn))),
    );
  }
}
