class SendQueueItem {
  const SendQueueItem({
    required this.itemId,
    required this.candidateId,
    required this.status,
    required this.order,
  });

  final String itemId;
  final String candidateId;
  final String status;
  final int order;
}
