import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_error.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  @override
  Future<String?> currentUserUid() async {
    return _firebaseAuth.currentUser?.uid;
  }

  @override
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) {
        throw const AppError('ログインユーザーを確認できませんでした。');
      }
      return uid;
    } on FirebaseAuthException catch (error) {
      throw AppError(_messageForCode(error.code), code: error.code);
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  static String _messageForCode(String code) {
    return switch (code) {
      'invalid-email' => 'メールアドレスの形式が正しくありません。',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'メールアドレスまたはパスワードが正しくありません。',
      'user-disabled' => 'このアカウントは無効化されています。',
      'too-many-requests' => 'ログイン試行が多すぎます。時間をおいて再試行してください。',
      _ => 'ログインに失敗しました。',
    };
  }
}
