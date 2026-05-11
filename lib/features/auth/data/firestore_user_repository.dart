import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/auth/role.dart';
import 'user_repository.dart';
import '../model/app_user.dart';

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<AppUser?> findByUid(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }

    final roleValue = data['role'];
    final role = roleValue is String ? Role.fromString(roleValue) : null;
    if (role == null) {
      return null;
    }

    final emailValue = data['email'];
    final displayNameValue = data['displayName'];

    return AppUser(
      uid: uid,
      role: role,
      isActive: data['isActive'] == true,
      email: emailValue is String ? emailValue : null,
      displayName: displayNameValue is String ? displayNameValue : null,
    );
  }
}
