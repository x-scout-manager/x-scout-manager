class SendHistory {
  const SendHistory({
    required this.historyId,
    required this.candidateId,
    required this.xUserId,
    required this.username,
    required this.messageBodySnapshot,
    required this.sendMethod,
  });

  final String historyId;
  final String candidateId;
  final String xUserId;
  final String username;
  final String messageBodySnapshot;
  final String sendMethod;
}
