import '../data/send_queue_repository.dart';
import '../model/send_queue_item.dart';

class LoadSendQueueItems {
  const LoadSendQueueItems(this._repository);

  final SendQueueRepository _repository;

  Stream<List<SendQueueItem>> call(String queueId) {
    return _repository.watchItems(queueId);
  }
}
