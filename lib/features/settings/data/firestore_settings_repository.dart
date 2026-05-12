import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'settings_repository.dart';
import '../model/scout_settings.dart';
import '../model/tag_setting.dart';

class FirestoreSettingsRepository implements SettingsRepository {
  FirestoreSettingsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  DocumentReference<Map<String, dynamic>> get _document =>
      _firestore.collection('settings').doc('scout');

  @override
  Stream<ScoutSettings?> watchScoutSettings() {
    return _document.snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return ScoutSettings.defaults;
      }
      return ScoutSettings.fromJson(data);
    });
  }

  @override
  Future<void> saveScoutSettings(ScoutSettings settings) async {
    await _saveData(settings.toJson());
  }

  @override
  Future<void> saveTags(List<TagSetting> tags) async {
    await _saveData({
      'tags': tags.where((tag) => tag.isActive).map((tag) => tag.tag).toList(),
    });
  }

  Future<void> _saveData(Map<String, Object?> data) async {
    final snapshot = await _document.get();
    await _document.set({
      ...data,
      if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _firebaseAuth.currentUser?.uid,
    }, SetOptions(merge: true));
  }
}
