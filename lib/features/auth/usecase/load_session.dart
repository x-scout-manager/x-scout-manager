import '../data/auth_repository.dart';
import '../data/user_repository.dart';
import '../model/app_user.dart';

class LoadSession {
  const LoadSession(this._authRepository, this._userRepository);

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  Future<AppUser?> call() async {
    final uid = await _authRepository.currentUserUid();
    if (uid == null) {
      return null;
    }
    final user = await _userRepository.findByUid(uid);
    if (user == null || !user.canManage) {
      await _authRepository.signOut();
      return null;
    }
    return user;
  }
}
