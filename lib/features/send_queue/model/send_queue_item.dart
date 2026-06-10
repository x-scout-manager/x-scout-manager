class SendQueueItem {
  const SendQueueItem({
    required this.itemId,
    required this.queueId,
    required this.candidateId,
    required this.xUserId,
    required this.username,
    required this.status,
    required this.order,
    this.displayName,
    this.templateId,
    this.sendHistoryId,
  });

  final String itemId;
  final String queueId;
  final String candidateId;
  final String xUserId;
  final String username;
  final String status;
  final int order;
  final String? displayName;
  final String? templateId;
  final String? sendHistoryId;

  bool get isPending => status == 'pending';
  bool get isSendable => status == 'pending' || status == 'failed';

  factory SendQueueItem.fromJson(String itemId, Map<String, dynamic> json) {
    return SendQueueItem(
      itemId: json['itemId'] is String ? json['itemId'] as String : itemId,
      queueId: json['queueId'] is String ? json['queueId'] as String : '',
      candidateId: json['candidateId'] is String
          ? json['candidateId'] as String
          : '',
      xUserId: json['xUserId'] is String ? json['xUserId'] as String : '',
      username: json['username'] is String ? json['username'] as String : '',
      status: json['status'] is String ? json['status'] as String : 'pending',
      order: json['order'] is num ? (json['order'] as num).toInt() : 0,
      displayName: json['displayName'] is String
          ? json['displayName'] as String
          : null,
      templateId: json['templateId'] is String
          ? json['templateId'] as String
          : null,
      sendHistoryId: json['sendHistoryId'] is String
          ? json['sendHistoryId'] as String
          : null,
    );
  }
}
