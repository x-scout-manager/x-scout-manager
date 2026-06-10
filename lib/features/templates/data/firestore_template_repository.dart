import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'template_repository.dart';
import '../model/dm_template.dart';

class FirestoreTemplateRepository implements TemplateRepository {
  FirestoreTemplateRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('templates');

  @override
  Stream<List<DmTemplate>> watchTemplates() {
    return _collection.snapshots().map((snapshot) {
      final templates = snapshot.docs
          .map((doc) => DmTemplate.fromJson(doc.id, doc.data()))
          .where((template) => !template.isDeleted)
          .toList();
      templates.sort((a, b) {
        final orderCompare = (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0);
        if (orderCompare != 0) {
          return orderCompare;
        }
        return a.name.compareTo(b.name);
      });
      return templates;
    });
  }

  @override
  Future<void> saveTemplate(DmTemplate template) async {
    final doc = template.templateId.isEmpty
        ? _collection.doc()
        : _collection.doc(template.templateId);
    final snapshot = await doc.get();
    final savedTemplate = template.copyWith(templateId: doc.id);

    await doc.set({
      ...savedTemplate.toJson(),
      if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
      if (!snapshot.exists) 'createdBy': _firebaseAuth.currentUser?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _firebaseAuth.currentUser?.uid,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteTemplate(String templateId) async {
    await _collection.doc(templateId).set({
      'isDeleted': true,
      'isActive': false,
      'deletedAt': FieldValue.serverTimestamp(),
      'deletedBy': _firebaseAuth.currentUser?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _firebaseAuth.currentUser?.uid,
    }, SetOptions(merge: true));
  }
}
