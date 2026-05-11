class DashboardSummary {
  const DashboardSummary({
    required this.candidateCount,
    required this.sentCount,
    required this.excludedCount,
  });

  final int candidateCount;
  final int sentCount;
  final int excludedCount;
}
