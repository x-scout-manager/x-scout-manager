import '../../../core/serialization/timestamps.dart';

class SendHistory {
  const SendHistory({
    required this.historyId,
    required this.candidateId,
    required this.xUserId,
    required this.username,
    required this.messageBodySnapshot,
    required this.sendMethod,
    required this.sentAt,
    required this.createdAt,
    this.displayName,
    this.queueId,
    this.queueItemId,
    this.templateId,
    this.templateName,
    this.sentBy,
    this.xDmEventId,
  });

  final String historyId;
  final String candidateId;
  final String xUserId;
  final String username;
  final String? displayName;
  final String? queueId;
  final String? queueItemId;
  final String? templateId;
  final String? templateName;
  final String messageBodySnapshot;
  final String sendMethod;
  final DateTime? sentAt;
  final String? sentBy;
  final String? xDmEventId;
  final DateTime? createdAt;

  String get displayUserName {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    if (username.isNotEmpty) {
      return '@$username';
    }
    return xUserId;
  }

  String get sendMethodLabel {
    return switch (sendMethod) {
      'api' => 'API',
      'manual' => '手動',
      _ => sendMethod,
    };
  }

  factory SendHistory.fromJson(String historyId, Map<String, dynamic> json) {
    return SendHistory(
      historyId: json['historyId'] is String
          ? json['historyId'] as String
          : historyId,
      candidateId: json['candidateId'] is String
          ? json['candidateId'] as String
          : '',
      xUserId: json['xUserId'] is String ? json['xUserId'] as String : '',
      username: json['username'] is String ? json['username'] as String : '',
      displayName: json['displayName'] is String
          ? json['displayName'] as String
          : null,
      queueId: json['queueId'] is String ? json['queueId'] as String : null,
      queueItemId: json['queueItemId'] is String
          ? json['queueItemId'] as String
          : null,
      templateId: json['templateId'] is String
          ? json['templateId'] as String
          : null,
      templateName: json['templateName'] is String
          ? json['templateName'] as String
          : null,
      messageBodySnapshot: json['messageBodySnapshot'] is String
          ? json['messageBodySnapshot'] as String
          : '',
      sendMethod: json['sendMethod'] is String
          ? json['sendMethod'] as String
          : '',
      sentAt: TimestampConverter.fromNullable(json['sentAt']),
      sentBy: json['sentBy'] is String ? json['sentBy'] as String : null,
      xDmEventId: json['xDmEventId'] is String
          ? json['xDmEventId'] as String
          : null,
      createdAt: TimestampConverter.fromNullable(json['createdAt']),
    );
  }
}
