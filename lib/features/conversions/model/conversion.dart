class Conversion {
  const Conversion({
    required this.conversionId,
    required this.candidateId,
    required this.xUserId,
    required this.username,
    required this.salesAmount,
    required this.rewardRate,
    required this.rewardAmount,
    required this.status,
  });

  final String conversionId;
  final String candidateId;
  final String xUserId;
  final String username;
  final num salesAmount;
  final num rewardRate;
  final num rewardAmount;
  final String status;
}
