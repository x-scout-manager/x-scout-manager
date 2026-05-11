import 'package:flutter_test/flutter_test.dart';
import 'package:x_scout_manager/app/app.dart';
import 'package:x_scout_manager/app/di/providers.dart';
import 'package:x_scout_manager/core/auth/role.dart';
import 'package:x_scout_manager/features/auth/data/auth_repository.dart';
import 'package:x_scout_manager/features/auth/data/user_repository.dart';
import 'package:x_scout_manager/features/auth/model/app_user.dart';

void main() {
  testWidgets('shows dashboard as initial page', (tester) async {
    await tester.pumpWidget(
      App(
        dependencies: AppDependencies(
          authRepository: _FakeAuthRepository(),
          userRepository: _FakeUserRepository(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ダッシュボード'), findsOneWidget);
    expect(find.text('候補'), findsOneWidget);
    expect(find.text('送信済み'), findsOneWidget);
    expect(find.text('除外'), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<String?> currentUserUid() async => 'admin-uid';

  @override
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    return 'admin-uid';
  }

  @override
  Future<void> signOut() async {}
}

class _FakeUserRepository implements UserRepository {
  @override
  Future<AppUser?> findByUid(String uid) async {
    return AppUser(uid: uid, role: Role.admin, isActive: true);
  }
}
