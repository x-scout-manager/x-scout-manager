import 'session.dart';

abstract interface class AuthService {
  Future<Session?> loadSession();
  Future<void> signOut();
}
