import '../model/send_queue.dart';
import '../model/send_queue_item.dart';

abstract interface class SendQueueRepository {
  Future<SendQueue?> findQueue(String queueId);
  Stream<SendQueue?> watchQueue(String queueId);
  Stream<List<SendQueueItem>> watchItems(String queueId);
}
