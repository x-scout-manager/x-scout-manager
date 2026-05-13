import 'package:cloud_firestore/cloud_firestore.dart';

import 'send_history_repository.dart';
import '../model/send_history.dart';

class FirestoreSendHistoryRepository implements SendHistoryRepository {
  FirestoreSendHistoryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('send_histories');

  @override
  Stream<List<SendHistory>> watchHistories() {
    return _collection.orderBy('sentAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => SendHistory.fromJson(doc.id, doc.data()))
          .toList();
    });
  }
}
