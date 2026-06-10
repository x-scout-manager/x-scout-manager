import 'package:flutter/material.dart';

import '../../../../core/ui/components/form_text_field.dart';
import '../../../../core/ui/components/primary_button.dart';
import '../../../../app/router/route_paths.dart';
import '../../vm/login_vm.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({required this.vm, super.key});

  final LoginVm vm;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = await widget.vm.submit();
    if (user == null || !mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(RoutePaths.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        final state = widget.vm.state;
        return SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FormTextField(
                label: 'メールアドレス',
                controller: _emailController,
                onChanged: widget.vm.updateEmail,
              ),
              const SizedBox(height: 16),
              FormTextField(
                label: 'パスワード',
                controller: _passwordController,
                obscureText: true,
                onChanged: widget.vm.updatePassword,
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: state.isLoading ? 'ログイン中' : 'ログイン',
                onPressed: state.isLoading ? null : _submit,
              ),
            ],
          ),
        );
      },
    );
  }
}
