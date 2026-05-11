import 'candidate_status.dart';

class Candidate {
  const Candidate({
    required this.candidateId,
    required this.xUserId,
    required this.username,
    required this.sourceTags,
    required this.status,
    required this.isExcluded,
    required this.isSent,
    this.displayName,
    this.profileText,
  });

  final String candidateId;
  final String xUserId;
  final String username;
  final List<String> sourceTags;
  final CandidateStatus status;
  final bool isExcluded;
  final bool isSent;
  final String? displayName;
  final String? profileText;
}
