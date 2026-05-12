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
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ExcludedAccount(
          xUserId: doc.id,
          username: data['username'] is String
              ? data['username'] as String
              : '',
          reason: data['reason'] is String ? data['reason'] as String : '',
        );
      }).toList();
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
