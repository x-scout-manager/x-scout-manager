import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'exclusion_repository.dart';
import '../model/excluded_account.dart';
import '../model/exclusion_keyword.dart';

class FirestoreExclusionRepository implements ExclusionRepository {
  FirestoreExclusionRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  DocumentReference<Map<String, dynamic>> get _settingsDocument =>
      _firestore.collection('settings').doc('scout');

  @override
  Stream<List<ExcludedAccount>> watchExcludedAccounts() {
    return _firestore.collection('excluded_accounts').snapshots().map((
      snapshot,
    ) {
      final accounts = snapshot.docs
          .map((doc) => ExcludedAccount.fromJson(doc.id, doc.data()))
          .toList();
      accounts.sort((a, b) {
        final aTime = a.updatedAt ?? a.createdAt;
        final bTime = b.updatedAt ?? b.createdAt;
        if (aTime == null && bTime == null) {
          return a.xUserId.compareTo(b.xUserId);
        }
        if (aTime == null) {
          return 1;
        }
        if (bTime == null) {
          return -1;
        }
        return bTime.compareTo(aTime);
      });
      return accounts;
    });
  }

  @override
  Stream<List<ExclusionKeyword>> watchKeywords() {
    return _settingsDocument.snapshots().map((snapshot) {
      final keywords = snapshot.data()?['exclusionKeywords'];
      if (keywords is! List) {
        return const <ExclusionKeyword>[];
      }
      return keywords
          .whereType<String>()
          .map((keyword) => ExclusionKeyword(keyword: keyword, isActive: true))
          .toList();
    });
  }

  @override
  Future<void> saveKeywords(List<ExclusionKeyword> keywords) async {
    final snapshot = await _settingsDocument.get();
    await _settingsDocument.set({
      'exclusionKeywords': keywords
          .where((keyword) => keyword.isActive)
          .map((keyword) => keyword.keyword)
          .toList(),
      if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _firebaseAuth.currentUser?.uid,
    }, SetOptions(merge: true));
  }
}
