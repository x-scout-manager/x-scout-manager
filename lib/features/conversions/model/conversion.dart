import '../../../core/serialization/timestamps.dart';

class Conversion {
  const Conversion({
    required this.conversionId,
    required this.candidateId,
    required this.xUserId,
    required this.username,
    required this.salesAmount,
    required this.status,
    this.displayName,
    this.sendHistoryId,
    this.rewardRate,
    this.rewardAmount,
    this.evidenceNote,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String conversionId;
  final String candidateId;
  final String xUserId;
  final String username;
  final String? displayName;
  final String? sendHistoryId;
  final num salesAmount;
  final num? rewardRate;
  final num? rewardAmount;
  final String? evidenceNote;
  final String status;
  final String? createdBy;
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

  String get statusLabel {
    return switch (status) {
      'draft' => '下書き',
      'reported' => '報告済み',
      'paid' => '支払済み',
      'canceled' => 'キャンセル',
      _ => status,
    };
  }

  factory Conversion.fromJson(String conversionId, Map<String, dynamic> json) {
    return Conversion(
      conversionId: json['conversionId'] is String
          ? json['conversionId'] as String
          : conversionId,
      candidateId: json['candidateId'] is String
          ? json['candidateId'] as String
          : '',
      xUserId: json['xUserId'] is String ? json['xUserId'] as String : '',
      username: json['username'] is String ? json['username'] as String : '',
      displayName: json['displayName'] is String
          ? json['displayName'] as String
          : null,
      sendHistoryId: json['sendHistoryId'] is String
          ? json['sendHistoryId'] as String
          : null,
      salesAmount: json['salesAmount'] is num ? json['salesAmount'] as num : 0,
      rewardRate: json['rewardRate'] is num ? json['rewardRate'] as num : null,
      rewardAmount: json['rewardAmount'] is num
          ? json['rewardAmount'] as num
          : null,
      evidenceNote: json['evidenceNote'] is String
          ? json['evidenceNote'] as String
          : null,
      status: json['status'] is String ? json['status'] as String : 'draft',
      createdBy: json['createdBy'] is String
          ? json['createdBy'] as String
          : null,
      createdAt: TimestampConverter.fromNullable(json['createdAt']),
      updatedAt: TimestampConverter.fromNullable(json['updatedAt']),
    );
  }
}
