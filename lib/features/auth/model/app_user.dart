import '../../../core/auth/role.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.role,
    required this.isActive,
    this.email,
    this.displayName,
  });

  final String uid;
  final Role role;
  final bool isActive;
  final String? email;
  final String? displayName;
}
