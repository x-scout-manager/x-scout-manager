import 'package:flutter/material.dart';

import '../../../../app/di/providers.dart';
import '../../../../core/ui/widgets/loading_view.dart';
import '../../vm/session_vm.dart';
import '../pages/login_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({required this.child, super.key});

  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final SessionVm _vm;

  @override
  void initState() {
    super.initState();
    final dependencies = AppProviders.read(context);
    _vm = SessionVm(dependencies.loadSession, dependencies.signOut)..load();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final state = _vm.state;
        if (state.isLoading) {
          return const LoadingView();
        }
        if (!state.isAuthenticated) {
          return const LoginPage();
        }
        return widget.child;
      },
    );
  }
}
