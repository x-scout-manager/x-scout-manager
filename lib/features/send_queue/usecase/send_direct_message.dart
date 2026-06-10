import '../data/send_queue_functions_repository.dart';

class SendDirectMessage {
  const SendDirectMessage(this._repository);

  final SendQueueFunctionsRepository _repository;

  Future<void> call({
    required String queueId,
    required String itemId,
    required String templateId,
    required String messageBody,
  }) {
    return _repository.sendDirectMessage(
      queueId: queueId,
      itemId: itemId,
      templateId: templateId,
      messageBody: messageBody,
    );
  }
}
