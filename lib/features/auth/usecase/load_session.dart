import '../data/user_repository.dart';
import '../model/app_user.dart';

class LoadSession {
  const LoadSession(this._repository);

  final UserRepository _repository;

  Future<AppUser?> call(String uid) => _repository.findByUid(uid);
}
