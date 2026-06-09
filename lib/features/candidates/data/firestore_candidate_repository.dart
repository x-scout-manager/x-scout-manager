import 'package:cloud_firestore/cloud_firestore.dart';

import 'candidate_repository.dart';
import '../model/candidate.dart';
import '../model/candidate_sync_run.dart';

class FirestoreCandidateRepository implements CandidateRepository {
  FirestoreCandidateRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('candidates');

  CollectionReference<Map<String, dynamic>> get _syncRunsCollection =>
      _firestore.collection('candidate_sync_runs');

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
  Stream<List<CandidateSyncRun>> watchRecentSyncRuns() {
    return _syncRunsCollection
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CandidateSyncRun.fromJson(doc.id, doc.data()))
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
