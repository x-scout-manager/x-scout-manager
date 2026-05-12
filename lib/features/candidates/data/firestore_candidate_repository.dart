import 'package:cloud_firestore/cloud_firestore.dart';

import 'candidate_repository.dart';
import '../model/candidate.dart';

class FirestoreCandidateRepository implements CandidateRepository {
  FirestoreCandidateRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('candidates');

  @override
  Stream<List<Candidate>> watchCandidates() {
    return _collection
        .orderBy('status')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Candidate.fromJson(doc.id, doc.data()))
              .toList();
        });
  }

  @override
  Future<Candidate?> findById(String candidateId) async {
    final snapshot = await _collection.doc(candidateId).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    return Candidate.fromJson(snapshot.id, data);
  }
}
