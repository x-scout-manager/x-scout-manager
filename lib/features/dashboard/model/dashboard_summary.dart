class DashboardSummary {
  const DashboardSummary({
    required this.candidateCount,
    required this.sentCount,
    required this.excludedCount,
    required this.unsentCandidateCount,
    required this.activeQueueCount,
  });

  final int candidateCount;
  final int sentCount;
  final int excludedCount;
  final int unsentCandidateCount;
  final int activeQueueCount;
}
