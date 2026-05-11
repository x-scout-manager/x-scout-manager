abstract interface class AuthRepository {
  Future<String?> currentUserUid();

  Future<String> signIn({required String email, required String password});

  Future<void> signOut();
}
