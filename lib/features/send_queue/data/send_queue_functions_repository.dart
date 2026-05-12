import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/functions_error_mapper.dart';

abstract interface class SendQueueFunctionsRepository {
  Future<String> createSendQueue(List<String> candidateIds);
  Future<void> sendDirectMessage(String queueId, String itemId);
  Future<void> markAsManuallySent({
    required String queueId,
    required String itemId,
    required String templateId,
    required String messageBody,
  });
}

class FirebaseSendQueueFunctionsRepository
    implements SendQueueFunctionsRepository {
  FirebaseSendQueueFunctionsRepository({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  final FirebaseFunctions _functions;

  @override
  Future<String> createSendQueue(List<String> candidateIds) async {
    try {
      final callable = _functions.httpsCallable('createSendQueue');
      final result = await callable.call<Map<String, dynamic>>({
        'candidateIds': candidateIds,
      });
      final queueId = result.data['queueId'];
      if (queueId is! String || queueId.isEmpty) {
        throw const AppError('送信キューIDを確認できませんでした。');
      }
      return queueId;
    } on AppError {
      rethrow;
    } catch (error) {
      throw FunctionsErrorMapper.map(error);
    }
  }

  @override
  Future<void> markAsManuallySent({
    required String queueId,
    required String itemId,
    required String templateId,
    required String messageBody,
  }) async {
    try {
      final callable = _functions.httpsCallable('markAsManuallySent');
      await callable.call<Map<String, dynamic>>({
        'queueId': queueId,
        'itemId': itemId,
        'templateId': templateId,
        'messageBody': messageBody,
      });
    } catch (error) {
      throw FunctionsErrorMapper.map(error);
    }
  }

  @override
  Future<void> sendDirectMessage(String queueId, String itemId) async {}
}
