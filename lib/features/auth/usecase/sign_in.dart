import '../../../core/errors/app_error.dart';
import '../data/auth_repository.dart';
import '../data/user_repository.dart';
import '../model/app_user.dart';

class SignIn {
  const SignIn(this._authRepository, this._userRepository);

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  Future<AppUser> call({
    required String email,
    required String password,
  }) async {
    final uid = await _authRepository.signIn(
      email: email.trim(),
      password: password,
    );
    final user = await _userRepository.findByUid(uid);
    if (user == null || !user.canManage) {
      await _authRepository.signOut();
      throw const AppError('管理者権限がありません。');
    }
    return user;
  }
}
