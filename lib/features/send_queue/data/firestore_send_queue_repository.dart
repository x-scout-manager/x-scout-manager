import 'package:cloud_firestore/cloud_firestore.dart';

import 'send_queue_repository.dart';
import '../model/send_queue.dart';
import '../model/send_queue_item.dart';

class FirestoreSendQueueRepository implements SendQueueRepository {
  FirestoreSendQueueRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('send_queues');

  @override
  Future<SendQueue?> findQueue(String queueId) async {
    final snapshot = await _collection.doc(queueId).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    return SendQueue.fromJson(snapshot.id, data);
  }

  @override
  Stream<List<SendQueue>> watchQueues() {
    return _collection.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => SendQueue.fromJson(doc.id, doc.data()))
          .toList();
    });
  }

  @override
  Stream<SendQueue?> watchQueue(String queueId) {
    return _collection.doc(queueId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return null;
      }
      return SendQueue.fromJson(snapshot.id, data);
    });
  }

  @override
  Stream<List<SendQueueItem>> watchItems(String queueId) {
    return _collection
        .doc(queueId)
        .collection('items')
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SendQueueItem.fromJson(doc.id, doc.data()))
              .toList();
        });
  }
}
