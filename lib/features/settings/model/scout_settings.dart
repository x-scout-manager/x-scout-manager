class ScoutSettings {
  const ScoutSettings({
    required this.tags,
    required this.exclusionKeywords,
    required this.searchMaxResults,
    required this.searchMaxPages,
    required this.recentSearchDays,
    required this.defaultRewardRate,
    required this.apiDmEnabled,
    required this.manualSendEnabled,
  });

  final List<String> tags;
  final List<String> exclusionKeywords;
  final int searchMaxResults;
  final int searchMaxPages;
  final int recentSearchDays;
  final num defaultRewardRate;
  final bool apiDmEnabled;
  final bool manualSendEnabled;

  static const defaults = ScoutSettings(
    tags: [],
    exclusionKeywords: [],
    searchMaxResults: 50,
    searchMaxPages: 1,
    recentSearchDays: 7,
    defaultRewardRate: 0.1,
    apiDmEnabled: false,
    manualSendEnabled: true,
  );

  ScoutSettings copyWith({
    List<String>? tags,
    List<String>? exclusionKeywords,
    int? searchMaxResults,
    int? searchMaxPages,
    int? recentSearchDays,
    num? defaultRewardRate,
    bool? apiDmEnabled,
    bool? manualSendEnabled,
  }) {
    return ScoutSettings(
      tags: tags ?? this.tags,
      exclusionKeywords: exclusionKeywords ?? this.exclusionKeywords,
      searchMaxResults: searchMaxResults ?? this.searchMaxResults,
      searchMaxPages: searchMaxPages ?? this.searchMaxPages,
      recentSearchDays: recentSearchDays ?? this.recentSearchDays,
      defaultRewardRate: defaultRewardRate ?? this.defaultRewardRate,
      apiDmEnabled: apiDmEnabled ?? this.apiDmEnabled,
      manualSendEnabled: manualSendEnabled ?? this.manualSendEnabled,
    );
  }

  factory ScoutSettings.fromJson(Map<String, dynamic> json) {
    return ScoutSettings(
      tags: _stringList(json['tags']),
      exclusionKeywords: _stringList(json['exclusionKeywords']),
      searchMaxResults: _intValue(json['searchMaxResults'], 50),
      searchMaxPages: _intValue(json['searchMaxPages'], 1),
      recentSearchDays: _intValue(json['recentSearchDays'], 7),
      defaultRewardRate: _numValue(json['defaultRewardRate'], 0.1),
      apiDmEnabled: json['apiDmEnabled'] == true,
      manualSendEnabled: json['manualSendEnabled'] is bool
          ? json['manualSendEnabled'] == true
          : true,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'tags': tags,
      'exclusionKeywords': exclusionKeywords,
      'searchMaxResults': searchMaxResults,
      'searchMaxPages': searchMaxPages,
      'recentSearchDays': recentSearchDays,
      'defaultRewardRate': defaultRewardRate,
      'apiDmEnabled': apiDmEnabled,
      'manualSendEnabled': manualSendEnabled,
    };
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) {
      return [];
    }
    return value.whereType<String>().toList();
  }

  static int _intValue(Object? value, int fallback) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return fallback;
  }

  static num _numValue(Object? value, num fallback) {
    return value is num ? value : fallback;
  }
}
