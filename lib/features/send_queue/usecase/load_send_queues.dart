import '../data/send_queue_repository.dart';
import '../model/send_queue.dart';

class LoadSendQueues {
  const LoadSendQueues(this._repository);

  final SendQueueRepository _repository;

  Stream<List<SendQueue>> call() {
    return _repository.watchQueues();
  }
}
