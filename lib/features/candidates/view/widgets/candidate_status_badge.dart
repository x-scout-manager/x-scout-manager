import 'package:flutter/material.dart';

import '../../model/candidate_status.dart';

class CandidateStatusBadge extends StatelessWidget {
  const CandidateStatusBadge({required this.status, super.key});

  final CandidateStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(status.label));
  }
}
