import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/errors/functions_error_mapper.dart';

abstract interface class CandidateFunctionsRepository {
  Future<void> syncCandidates();
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
  Future<void> syncCandidates() async {}

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
