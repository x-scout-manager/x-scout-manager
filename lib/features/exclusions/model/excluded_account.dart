import '../../../core/serialization/timestamps.dart';

class ExcludedAccount {
  const ExcludedAccount({
    required this.candidateId,
    required this.xUserId,
    required this.username,
    this.displayName,
    this.profileTextSnapshot,
    this.matchedKeywords = const [],
    this.reason,
    this.source,
    this.createdAt,
    this.updatedAt,
  });

  final String candidateId;
  final String xUserId;
  final String username;
  final String? displayName;
  final String? profileTextSnapshot;
  final List<String> matchedKeywords;
  final String? reason;
  final String? source;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayUserName {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    if (username.isNotEmpty) {
      return '@$username';
    }
    return xUserId;
  }

  factory ExcludedAccount.fromJson(String xUserId, Map<String, dynamic> json) {
    final keywords = json['matchedKeywords'];
    return ExcludedAccount(
      candidateId: json['candidateId'] is String
          ? json['candidateId'] as String
          : xUserId,
      xUserId: json['xUserId'] is String ? json['xUserId'] as String : xUserId,
      username: json['username'] is String ? json['username'] as String : '',
      displayName: json['displayName'] is String
          ? json['displayName'] as String
          : null,
      profileTextSnapshot: json['profileTextSnapshot'] is String
          ? json['profileTextSnapshot'] as String
          : null,
      matchedKeywords: keywords is List
          ? keywords.whereType<String>().toList()
          : const [],
      reason: json['reason'] is String ? json['reason'] as String : null,
      source: json['source'] is String ? json['source'] as String : null,
      createdAt: TimestampConverter.fromNullable(json['createdAt']),
      updatedAt: TimestampConverter.fromNullable(json['updatedAt']),
    );
  }
}
