import 'package:flutter/material.dart';

import '../../../../core/ui/components/form_text_field.dart';
import '../../../../core/ui/components/primary_button.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FormTextField(label: 'メールアドレス'),
          SizedBox(height: 16),
          FormTextField(label: 'パスワード', obscureText: true),
          SizedBox(height: 24),
          PrimaryButton(label: 'ログイン', onPressed: null),
        ],
      ),
    );
  }
}
