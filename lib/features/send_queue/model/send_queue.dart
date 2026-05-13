import '../../../core/serialization/timestamps.dart';

class SendQueue {
  const SendQueue({
    required this.queueId,
    required this.status,
    required this.currentIndex,
    required this.totalCount,
    required this.completedCount,
    required this.skippedCount,
    required this.failedCount,
    this.name,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  final String queueId;
  final String? name;
  final String status;
  final int currentIndex;
  final int totalCount;
  final int completedCount;
  final int skippedCount;
  final int failedCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  bool get isActive => status == 'active';

  String get statusLabel {
    return switch (status) {
      'active' => '進行中',
      'completed' => '完了',
      'canceled' => 'キャンセル',
      _ => status,
    };
  }

  factory SendQueue.fromJson(String queueId, Map<String, dynamic> json) {
    return SendQueue(
      queueId: json['queueId'] is String ? json['queueId'] as String : queueId,
      name: json['name'] is String ? json['name'] as String : null,
      status: json['status'] is String ? json['status'] as String : 'active',
      currentIndex: json['currentIndex'] is num
          ? (json['currentIndex'] as num).toInt()
          : 0,
      totalCount: json['totalCount'] is num
          ? (json['totalCount'] as num).toInt()
          : 0,
      completedCount: json['completedCount'] is num
          ? (json['completedCount'] as num).toInt()
          : 0,
      skippedCount: json['skippedCount'] is num
          ? (json['skippedCount'] as num).toInt()
          : 0,
      failedCount: json['failedCount'] is num
          ? (json['failedCount'] as num).toInt()
          : 0,
      createdAt: TimestampConverter.fromNullable(json['createdAt']),
      updatedAt: TimestampConverter.fromNullable(json['updatedAt']),
      createdBy: json['createdBy'] is String
          ? json['createdBy'] as String
          : null,
    );
  }
}
