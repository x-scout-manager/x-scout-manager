import '../model/app_user.dart';

abstract interface class UserRepository {
  Future<AppUser?> findByUid(String uid);
}
