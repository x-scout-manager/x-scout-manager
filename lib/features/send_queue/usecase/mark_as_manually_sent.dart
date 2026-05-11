import '../data/send_queue_functions_repository.dart';

class MarkAsManuallySent {
  const MarkAsManuallySent(this._repository);

  final SendQueueFunctionsRepository _repository;

  Future<void> call(String queueId, String itemId) {
    return _repository.markAsManuallySent(queueId, itemId);
  }
}
