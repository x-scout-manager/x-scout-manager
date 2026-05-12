import '../data/send_queue_functions_repository.dart';

class MarkAsManuallySent {
  const MarkAsManuallySent(this._repository);

  final SendQueueFunctionsRepository _repository;

  Future<void> call({
    required String queueId,
    required String itemId,
    required String templateId,
    required String messageBody,
  }) {
    return _repository.markAsManuallySent(
      queueId: queueId,
      itemId: itemId,
      templateId: templateId,
      messageBody: messageBody,
    );
  }
}
