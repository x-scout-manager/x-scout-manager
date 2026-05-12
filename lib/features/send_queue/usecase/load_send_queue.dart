import '../data/send_queue_repository.dart';
import '../model/send_queue.dart';

class LoadSendQueue {
  const LoadSendQueue(this._repository);

  final SendQueueRepository _repository;

  Stream<SendQueue?> call(String queueId) {
    return _repository.watchQueue(queueId);
  }
}
