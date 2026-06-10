import '../data/send_queue_functions_repository.dart';

class DeleteSendQueue {
  const DeleteSendQueue(this._repository);

  final SendQueueFunctionsRepository _repository;

  Future<void> call(String queueId) {
    return _repository.deleteSendQueue(queueId);
  }
}
