import 'auth_repository.dart';
import '../model/app_user.dart';

class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository();

  @override
  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError('Firebase Auth setup is not configured yet.');
  }

  @override
  Future<void> signOut() async {
    throw UnimplementedError('Firebase Auth setup is not configured yet.');
  }
}
