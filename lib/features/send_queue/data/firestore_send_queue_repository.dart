import 'send_queue_repository.dart';
import '../model/send_queue.dart';
import '../model/send_queue_item.dart';

class FirestoreSendQueueRepository implements SendQueueRepository {
  const FirestoreSendQueueRepository();

  @override
  Future<SendQueue?> findQueue(String queueId) async => null;

  @override
  Stream<List<SendQueueItem>> watchItems(String queueId) {
    return const Stream.empty();
  }
}
