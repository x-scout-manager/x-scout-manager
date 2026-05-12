import 'package:flutter_test/flutter_test.dart';
import 'package:x_scout_manager/app/app.dart';
import 'package:x_scout_manager/app/di/providers.dart';
import 'package:x_scout_manager/core/auth/role.dart';
import 'package:x_scout_manager/features/auth/data/auth_repository.dart';
import 'package:x_scout_manager/features/auth/data/user_repository.dart';
import 'package:x_scout_manager/features/auth/model/app_user.dart';
import 'package:x_scout_manager/features/exclusions/data/exclusion_repository.dart';
import 'package:x_scout_manager/features/exclusions/model/excluded_account.dart';
import 'package:x_scout_manager/features/exclusions/model/exclusion_keyword.dart';
import 'package:x_scout_manager/features/settings/data/settings_repository.dart';
import 'package:x_scout_manager/features/settings/model/scout_settings.dart';
import 'package:x_scout_manager/features/settings/model/tag_setting.dart';
import 'package:x_scout_manager/features/templates/data/template_repository.dart';
import 'package:x_scout_manager/features/templates/model/dm_template.dart';

void main() {
  testWidgets('shows dashboard as initial page', (tester) async {
    await tester.pumpWidget(
      App(
        dependencies: AppDependencies(
          authRepository: _FakeAuthRepository(),
          userRepository: _FakeUserRepository(),
          settingsRepository: _FakeSettingsRepository(),
          exclusionRepository: _FakeExclusionRepository(),
          templateRepository: _FakeTemplateRepository(),
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

class _FakeSettingsRepository implements SettingsRepository {
  @override
  Stream<ScoutSettings?> watchScoutSettings() {
    return Stream.value(ScoutSettings.defaults);
  }

  @override
  Future<void> saveScoutSettings(ScoutSettings settings) async {}

  @override
  Future<void> saveTags(List<TagSetting> tags) async {}
}

class _FakeExclusionRepository implements ExclusionRepository {
  @override
  Stream<List<ExcludedAccount>> watchExcludedAccounts() {
    return Stream.value(const []);
  }

  @override
  Stream<List<ExclusionKeyword>> watchKeywords() {
    return Stream.value(const []);
  }

  @override
  Future<void> saveKeywords(List<ExclusionKeyword> keywords) async {}
}

class _FakeTemplateRepository implements TemplateRepository {
  @override
  Stream<List<DmTemplate>> watchTemplates() {
    return Stream.value(const []);
  }

  @override
  Future<void> saveTemplate(DmTemplate template) async {}
}
