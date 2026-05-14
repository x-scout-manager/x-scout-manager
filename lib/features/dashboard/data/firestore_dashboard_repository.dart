import 'package:cloud_firestore/cloud_firestore.dart';

import 'dashboard_repository.dart';
import '../model/dashboard_summary.dart';

class FirestoreDashboardRepository implements DashboardRepository {
  FirestoreDashboardRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<DashboardSummary> loadSummary() async {
    final candidates = _firestore.collection('candidates');
    final sendHistories = _firestore.collection('send_histories');
    final excludedAccounts = _firestore.collection('excluded_accounts');
    final sendQueues = _firestore.collection('send_queues');

    final [
      candidateCount,
      sentCount,
      excludedCount,
      unsentCandidateCount,
      activeQueueCount,
    ] = await Future.wait([
      _count(candidates),
      _count(sendHistories),
      _count(excludedAccounts),
      _count(candidates.where('status', isEqualTo: 'candidate')),
      _count(sendQueues.where('status', isEqualTo: 'active')),
    ]);

    return DashboardSummary(
      candidateCount: candidateCount,
      sentCount: sentCount,
      excludedCount: excludedCount,
      unsentCandidateCount: unsentCandidateCount,
      activeQueueCount: activeQueueCount,
    );
  }

  Future<int> _count(Query<Map<String, dynamic>> query) async {
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }
}
