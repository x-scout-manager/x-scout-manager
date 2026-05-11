import 'role.dart';

class Session {
  const Session({
    required this.uid,
    required this.role,
    required this.isActive,
  });

  final String uid;
  final Role role;
  final bool isActive;

  bool get canManage => role == Role.admin && isActive;
}
