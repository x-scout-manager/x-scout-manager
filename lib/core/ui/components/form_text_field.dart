import 'package:flutter/material.dart';

class FormTextField extends StatelessWidget {
  const FormTextField({
    required this.label,
    this.controller,
    this.onChanged,
    this.obscureText = false,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      obscureText: obscureText,
      onChanged: onChanged,
    );
  }
}
