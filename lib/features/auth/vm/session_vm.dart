import 'package:flutter/foundation.dart';

import '../model/app_user.dart';
import '../usecase/load_session.dart';
import '../usecase/sign_out.dart';

class SessionState {
  const SessionState({this.user, this.isLoading = true});

  final AppUser? user;
  final bool isLoading;

  bool get isAuthenticated => user != null;
}

class SessionVm extends ChangeNotifier {
  SessionVm(this._loadSession, this._signOut);

  final LoadSession _loadSession;
  final SignOut _signOut;

  SessionState _state = const SessionState();

  SessionState get state => _state;

  Future<void> load() async {
    _state = const SessionState();
    notifyListeners();
    final user = await _loadSession();
    _state = SessionState(user: user, isLoading: false);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _signOut();
    _state = const SessionState(isLoading: false);
    notifyListeners();
  }
}
