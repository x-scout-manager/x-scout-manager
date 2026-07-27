import 'package:cloud_firestore/cloud_firestore.dart';

import 'candidate_repository.dart';
import '../model/candidate.dart';
import '../model/candidate_page.dart';
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
  Future<CandidatePage> loadCandidatePage({
    CandidatePageCursor? startAfter,
    int pageSize = 50,
  }) async {
    final effectivePageSize = pageSize.clamp(1, 100);
    Query<Map<String, dynamic>> query = _collection
        .orderBy('status')
        .orderBy('updatedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
    if (startAfter != null) {
      query = query.startAfter([
        startAfter.status,
        Timestamp.fromDate(startAfter.updatedAt),
        startAfter.candidateId,
      ]);
    }

    final snapshot = await query.limit(effectivePageSize + 1).get();
    final visibleDocs = snapshot.docs.take(effectivePageSize).toList();
    final hasNextPage = snapshot.docs.length > effectivePageSize;
    CandidatePageCursor? nextCursor;
    if (hasNextPage && visibleDocs.isNotEmpty) {
      final lastDoc = visibleDocs.last;
      final data = lastDoc.data();
      final updatedAt = data['updatedAt'];
      nextCursor = CandidatePageCursor(
        candidateId: lastDoc.id,
        status: data['status'] is String
            ? data['status'] as String
            : 'candidate',
        updatedAt: updatedAt is Timestamp
            ? updatedAt.toDate()
            : DateTime.fromMillisecondsSinceEpoch(0),
      );
    }

    return CandidatePage(
      candidates: visibleDocs
          .map((doc) => Candidate.fromJson(doc.id, doc.data()))
          .toList(),
      nextCursor: nextCursor,
    );
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
