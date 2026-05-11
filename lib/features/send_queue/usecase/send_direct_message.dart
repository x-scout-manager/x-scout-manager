import '../data/send_queue_functions_repository.dart';

class SendDirectMessage {
  const SendDirectMessage(this._repository);

  final SendQueueFunctionsRepository _repository;

  Future<void> call(String queueId, String itemId) {
    return _repository.sendDirectMessage(queueId, itemId);
  }
}
