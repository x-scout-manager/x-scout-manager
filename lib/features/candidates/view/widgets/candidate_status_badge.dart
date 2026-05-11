import 'package:flutter/material.dart';

class CandidateStatusBadge extends StatelessWidget {
  const CandidateStatusBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}
