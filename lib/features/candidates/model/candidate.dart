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
    this.profileUrl,
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
  final String? profileUrl;

  bool get canSend =>
      status == CandidateStatus.candidate && !isExcluded && !isSent;

  factory Candidate.fromJson(String candidateId, Map<String, dynamic> json) {
    final statusValue = json['status'];
    final sourceTagsValue = json['sourceTags'];
    return Candidate(
      candidateId: candidateId,
      xUserId: json['xUserId'] is String
          ? json['xUserId'] as String
          : candidateId,
      username: json['username'] is String ? json['username'] as String : '',
      displayName: json['displayName'] is String
          ? json['displayName'] as String
          : null,
      profileText: json['profileText'] is String
          ? json['profileText'] as String
          : null,
      profileUrl: json['profileUrl'] is String
          ? json['profileUrl'] as String
          : null,
      sourceTags: sourceTagsValue is List
          ? sourceTagsValue.whereType<String>().toList()
          : const [],
      status: statusValue is String
          ? CandidateStatus.fromString(statusValue)
          : CandidateStatus.candidate,
      isExcluded: json['isExcluded'] == true,
      isSent: json['isSent'] == true,
    );
  }
}
