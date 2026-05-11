abstract interface class SendQueueFunctionsRepository {
  Future<String> createSendQueue(List<String> candidateIds);
  Future<void> sendDirectMessage(String queueId, String itemId);
  Future<void> markAsManuallySent(String queueId, String itemId);
}

class FirebaseSendQueueFunctionsRepository
    implements SendQueueFunctionsRepository {
  const FirebaseSendQueueFunctionsRepository();

  @override
  Future<String> createSendQueue(List<String> candidateIds) async {
    throw UnimplementedError('Cloud Functions setup is not configured yet.');
  }

  @override
  Future<void> markAsManuallySent(String queueId, String itemId) async {}

  @override
  Future<void> sendDirectMessage(String queueId, String itemId) async {}
}
