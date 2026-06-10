import 'package:flutter_test/flutter_test.dart';
import 'package:x_scout_manager/app/app.dart';
import 'package:x_scout_manager/app/di/providers.dart';
import 'package:x_scout_manager/core/auth/role.dart';
import 'package:x_scout_manager/features/auth/data/auth_repository.dart';
import 'package:x_scout_manager/features/auth/data/user_repository.dart';
import 'package:x_scout_manager/features/auth/model/app_user.dart';
import 'package:x_scout_manager/features/candidates/data/candidate_repository.dart';
import 'package:x_scout_manager/features/candidates/data/candidate_functions_repository.dart';
import 'package:x_scout_manager/features/candidates/model/candidate.dart';
import 'package:x_scout_manager/features/candidates/model/candidate_sync_run.dart';
import 'package:x_scout_manager/features/conversions/data/conversion_functions_repository.dart';
import 'package:x_scout_manager/features/conversions/data/conversion_repository.dart';
import 'package:x_scout_manager/features/conversions/model/conversion.dart';
import 'package:x_scout_manager/features/dashboard/data/dashboard_repository.dart';
import 'package:x_scout_manager/features/dashboard/model/dashboard_summary.dart';
import 'package:x_scout_manager/features/exclusions/data/exclusion_repository.dart';
import 'package:x_scout_manager/features/exclusions/model/excluded_account.dart';
import 'package:x_scout_manager/features/exclusions/model/exclusion_keyword.dart';
import 'package:x_scout_manager/features/histories/data/send_history_repository.dart';
import 'package:x_scout_manager/features/histories/model/send_history.dart';
import 'package:x_scout_manager/features/settings/data/settings_repository.dart';
import 'package:x_scout_manager/features/settings/model/scout_settings.dart';
import 'package:x_scout_manager/features/settings/model/tag_setting.dart';
import 'package:x_scout_manager/features/send_queue/data/send_queue_repository.dart';
import 'package:x_scout_manager/features/send_queue/data/send_queue_functions_repository.dart';
import 'package:x_scout_manager/features/send_queue/model/send_queue.dart';
import 'package:x_scout_manager/features/send_queue/model/send_queue_item.dart';
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
          dashboardRepository: _FakeDashboardRepository(),
          exclusionRepository: _FakeExclusionRepository(),
          templateRepository: _FakeTemplateRepository(),
          candidateRepository: _FakeCandidateRepository(),
          candidateFunctionsRepository: _FakeCandidateFunctionsRepository(),
          conversionRepository: _FakeConversionRepository(),
          conversionFunctionsRepository: _FakeConversionFunctionsRepository(),
          sendHistoryRepository: _FakeSendHistoryRepository(),
          sendQueueRepository: _FakeSendQueueRepository(),
          sendQueueFunctionsRepository: _FakeSendQueueFunctionsRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

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

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSummary> loadSummary() async {
    return const DashboardSummary(
      candidateCount: 0,
      sentCount: 0,
      excludedCount: 0,
      unsentCandidateCount: 0,
      activeQueueCount: 0,
    );
  }
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
  Future<void> deleteTemplate(String templateId) async {}

  @override
  Stream<List<DmTemplate>> watchTemplates() {
    return Stream.value(const []);
  }

  @override
  Future<void> saveTemplate(DmTemplate template) async {}
}

class _FakeCandidateRepository implements CandidateRepository {
  @override
  Stream<List<Candidate>> watchCandidates() {
    return Stream.value(const []);
  }

  @override
  Stream<List<CandidateSyncRun>> watchRecentSyncRuns() {
    return Stream.value(const []);
  }

  @override
  Future<Candidate?> findById(String candidateId) async {
    return null;
  }
}

class _FakeCandidateFunctionsRepository
    implements CandidateFunctionsRepository {
  @override
  Future<void> excludeCandidate({
    required String candidateId,
    String? reason,
  }) async {}

  @override
  Future<void> restoreCandidate(String candidateId) async {}

  @override
  Future<SyncCandidatesResult> syncCandidates() async {
    return const SyncCandidatesResult(
      createdCount: 0,
      updatedCount: 0,
      excludedCount: 0,
      skippedSentCount: 0,
      totalFoundCount: 0,
      tags: [],
    );
  }

  @override
  Future<RevertCandidateSyncRunResult> revertCandidateSyncRun(
    String runId,
  ) async {
    return RevertCandidateSyncRunResult(
      runId: runId,
      revertedCount: 0,
      deletedCount: 0,
      skippedCount: 0,
    );
  }

  @override
  Future<CleanupRevertedCandidatesResult> cleanupRevertedCandidates() async {
    return const CleanupRevertedCandidatesResult(
      restoredCount: 0,
      deletedCount: 0,
      skippedCount: 0,
    );
  }
}

class _FakeConversionRepository implements ConversionRepository {
  @override
  Stream<List<Conversion>> watchConversions() {
    return Stream.value(const []);
  }
}

class _FakeConversionFunctionsRepository
    implements ConversionFunctionsRepository {
  @override
  Future<String> createConversion({
    required String sendHistoryId,
    required num salesAmount,
    String? evidenceNote,
  }) async {
    return 'conversion-id';
  }
}

class _FakeSendQueueFunctionsRepository
    implements SendQueueFunctionsRepository {
  @override
  Future<String> createSendQueue(List<String> candidateIds) async {
    return 'queue-id';
  }

  @override
  Future<void> deleteSendQueue(String queueId) async {}

  @override
  Future<void> markAsManuallySent({
    required String queueId,
    required String itemId,
    required String templateId,
    required String messageBody,
  }) async {}

  @override
  Future<void> sendDirectMessage({
    required String queueId,
    required String itemId,
    required String templateId,
    required String messageBody,
  }) async {}
}

class _FakeSendQueueRepository implements SendQueueRepository {
  @override
  Future<SendQueue?> findQueue(String queueId) async {
    return null;
  }

  @override
  Stream<List<SendQueue>> watchQueues() {
    return Stream.value(const []);
  }

  @override
  Stream<SendQueue?> watchQueue(String queueId) {
    return Stream.value(null);
  }

  @override
  Stream<List<SendQueueItem>> watchItems(String queueId) {
    return Stream.value(const []);
  }
}

class _FakeSendHistoryRepository implements SendHistoryRepository {
  @override
  Stream<List<SendHistory>> watchHistories() {
    return Stream.value(const []);
  }
}
