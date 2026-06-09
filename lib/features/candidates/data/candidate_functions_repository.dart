import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/errors/functions_error_mapper.dart';

class SyncCandidatesResult {
  const SyncCandidatesResult({
    required this.createdCount,
    required this.updatedCount,
    required this.excludedCount,
    required this.skippedSentCount,
    required this.totalFoundCount,
    required this.tags,
    this.runId,
  });

  final int createdCount;
  final int updatedCount;
  final int excludedCount;
  final int skippedSentCount;
  final int totalFoundCount;
  final List<String> tags;
  final String? runId;

  factory SyncCandidatesResult.fromJson(Map<Object?, Object?> json) {
    return SyncCandidatesResult(
      createdCount: _intValue(json['createdCount']),
      updatedCount: _intValue(json['updatedCount']),
      excludedCount: _intValue(json['excludedCount']),
      skippedSentCount: _intValue(json['skippedSentCount']),
      totalFoundCount: _intValue(json['totalFoundCount']),
      tags: json['tags'] is List
          ? (json['tags'] as List).whereType<String>().toList()
          : const [],
      runId: json['runId'] is String ? json['runId'] as String : null,
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

class RevertCandidateSyncRunResult {
  const RevertCandidateSyncRunResult({
    required this.runId,
    required this.revertedCount,
    required this.deletedCount,
    required this.skippedCount,
  });

  final String runId;
  final int revertedCount;
  final int deletedCount;
  final int skippedCount;

  factory RevertCandidateSyncRunResult.fromJson(Map<Object?, Object?> json) {
    return RevertCandidateSyncRunResult(
      runId: json['runId'] is String ? json['runId'] as String : '',
      revertedCount: SyncCandidatesResult._intValue(json['revertedCount']),
      deletedCount: SyncCandidatesResult._intValue(json['deletedCount']),
      skippedCount: SyncCandidatesResult._intValue(json['skippedCount']),
    );
  }
}

abstract interface class CandidateFunctionsRepository {
  Future<SyncCandidatesResult> syncCandidates();
  Future<RevertCandidateSyncRunResult> revertCandidateSyncRun(String runId);
  Future<void> excludeCandidate({required String candidateId, String? reason});
  Future<void> restoreCandidate(String candidateId);
}

class FirebaseCandidateFunctionsRepository
    implements CandidateFunctionsRepository {
  FirebaseCandidateFunctionsRepository({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  final FirebaseFunctions _functions;

  @override
  Future<SyncCandidatesResult> syncCandidates() async {
    try {
      final callable = _functions.httpsCallable('syncCandidates');
      final result = await callable.call<Map<Object?, Object?>>({});
      return SyncCandidatesResult.fromJson(result.data);
    } catch (error) {
      throw FunctionsErrorMapper.map(error);
    }
  }

  @override
  Future<RevertCandidateSyncRunResult> revertCandidateSyncRun(
    String runId,
  ) async {
    try {
      final callable = _functions.httpsCallable('revertCandidateSyncRun');
      final result = await callable.call<Map<Object?, Object?>>({
        'runId': runId,
      });
      return RevertCandidateSyncRunResult.fromJson(result.data);
    } catch (error) {
      throw FunctionsErrorMapper.map(error);
    }
  }

  @override
  Future<void> excludeCandidate({
    required String candidateId,
    String? reason,
  }) async {
    try {
      final callable = _functions.httpsCallable('excludeCandidate');
      await callable.call<Map<String, dynamic>>({
        'candidateId': candidateId,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      });
    } catch (error) {
      throw FunctionsErrorMapper.map(error);
    }
  }

  @override
  Future<void> restoreCandidate(String candidateId) async {
    try {
      final callable = _functions.httpsCallable('restoreCandidate');
      await callable.call<Map<String, dynamic>>({'candidateId': candidateId});
    } catch (error) {
      throw FunctionsErrorMapper.map(error);
    }
  }
}
