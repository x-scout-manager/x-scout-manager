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
  });

  final String queueId;
  final String? name;
  final String status;
  final int currentIndex;
  final int totalCount;
  final int completedCount;
  final int skippedCount;
  final int failedCount;

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
    );
  }
}
