import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../model/app_user.dart';
import '../usecase/sign_in.dart';

class LoginState {
  const LoginState({
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.errorMessage,
  });

  final String email;
  final String password;
  final bool isLoading;
  final String? errorMessage;
}

class LoginVm extends ChangeNotifier {
  LoginVm(this._signIn);

  final SignIn _signIn;

  LoginState _state = const LoginState();

  LoginState get state => _state;

  void updateEmail(String email) {
    _state = LoginState(
      email: email,
      password: _state.password,
      errorMessage: _state.errorMessage,
    );
    notifyListeners();
  }

  void updatePassword(String password) {
    _state = LoginState(
      email: _state.email,
      password: password,
      errorMessage: _state.errorMessage,
    );
    notifyListeners();
  }

  Future<AppUser?> submit() async {
    if (_state.email.trim().isEmpty || _state.password.isEmpty) {
      _state = LoginState(
        email: _state.email,
        password: _state.password,
        errorMessage: 'メールアドレスとパスワードを入力してください。',
      );
      notifyListeners();
      return null;
    }

    _state = LoginState(
      email: _state.email,
      password: _state.password,
      isLoading: true,
    );
    notifyListeners();

    try {
      final user = await _signIn(
        email: _state.email,
        password: _state.password,
      );
      _state = LoginState(email: _state.email, password: _state.password);
      notifyListeners();
      return user;
    } on AppError catch (error) {
      _state = LoginState(
        email: _state.email,
        password: _state.password,
        errorMessage: error.message,
      );
      notifyListeners();
      return null;
    } catch (_) {
      _state = LoginState(
        email: _state.email,
        password: _state.password,
        errorMessage: 'ログインに失敗しました。',
      );
      notifyListeners();
      return null;
    }
  }
}
