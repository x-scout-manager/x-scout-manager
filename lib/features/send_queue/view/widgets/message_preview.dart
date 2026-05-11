import 'package:flutter/material.dart';

class MessagePreview extends StatelessWidget {
  const MessagePreview({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SelectableText(message);
  }
}
