import '../../../core/serialization/timestamps.dart';

class CandidateSyncRun {
  const CandidateSyncRun({
    required this.runId,
    required this.status,
    required this.tags,
    required this.tagSearchMode,
    required this.createdAt,
    this.completedAt,
    this.revertedAt,
    this.createdCount = 0,
    this.updatedCount = 0,
    this.excludedCount = 0,
    this.totalFoundCount = 0,
  });

  final String runId;
  final String status;
  final List<String> tags;
  final String tagSearchMode;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final DateTime? revertedAt;
  final int createdCount;
  final int updatedCount;
  final int excludedCount;
  final int totalFoundCount;

  bool get canRevert => status == 'completed';

  String get statusLabel {
    return switch (status) {
      'running' => '実行中',
      'completed' => '完了',
      'reverted' => '解除済み',
      'failed' => '失敗',
      _ => status,
    };
  }

  String get tagSearchModeLabel {
    return switch (tagSearchMode) {
      'any' => 'OR',
      'all' => 'AND',
      _ => 'タグごと',
    };
  }

  factory CandidateSyncRun.fromJson(String runId, Map<String, dynamic> json) {
    final result = json['result'] is Map
        ? Map<String, dynamic>.from(json['result'] as Map)
        : const <String, dynamic>{};
    final tagsValue = json['tags'];
    return CandidateSyncRun(
      runId: json['runId'] is String ? json['runId'] as String : runId,
      status: json['status'] is String ? json['status'] as String : '',
      tags: tagsValue is List ? tagsValue.whereType<String>().toList() : [],
      tagSearchMode: json['tagSearchMode'] is String
          ? json['tagSearchMode'] as String
          : 'per_tag',
      createdAt: TimestampConverter.fromNullable(json['createdAt']),
      completedAt: TimestampConverter.fromNullable(json['completedAt']),
      revertedAt: TimestampConverter.fromNullable(json['revertedAt']),
      createdCount: _intValue(result['createdCount']),
      updatedCount: _intValue(result['updatedCount']),
      excludedCount: _intValue(result['excludedCount']),
      totalFoundCount: _intValue(result['totalFoundCount']),
    );
  }

  static int _intValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}
