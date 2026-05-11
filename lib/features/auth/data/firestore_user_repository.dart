import 'user_repository.dart';
import '../model/app_user.dart';

class FirestoreUserRepository implements UserRepository {
  const FirestoreUserRepository();

  @override
  Future<AppUser?> findByUid(String uid) async {
    throw UnimplementedError('Firestore setup is not configured yet.');
  }
}
