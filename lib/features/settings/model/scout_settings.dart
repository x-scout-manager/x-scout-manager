class ScoutSettings {
  const ScoutSettings({
    required this.tags,
    required this.exclusionKeywords,
    required this.defaultRewardRate,
  });

  final List<String> tags;
  final List<String> exclusionKeywords;
  final num defaultRewardRate;
}
