class SendQueue {
  const SendQueue({
    required this.queueId,
    required this.status,
    required this.totalCount,
    required this.completedCount,
  });

  final String queueId;
  final String status;
  final int totalCount;
  final int completedCount;
}
