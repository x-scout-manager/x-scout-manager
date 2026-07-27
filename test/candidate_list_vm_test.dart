import 'package:flutter_test/flutter_test.dart';
import 'package:x_scout_manager/features/candidates/data/candidate_functions_repository.dart';
import 'package:x_scout_manager/features/candidates/data/candidate_repository.dart';
import 'package:x_scout_manager/features/candidates/model/candidate.dart';
import 'package:x_scout_manager/features/candidates/model/candidate_status.dart';
import 'package:x_scout_manager/features/candidates/model/candidate_sync_run.dart';
import 'package:x_scout_manager/features/candidates/usecase/cleanup_reverted_candidates.dart';
import 'package:x_scout_manager/features/candidates/usecase/load_candidate_sync_runs.dart';
import 'package:x_scout_manager/features/candidates/usecase/load_candidates.dart';
import 'package:x_scout_manager/features/candidates/usecase/revert_candidate_sync_run.dart';
import 'package:x_scout_manager/features/candidates/usecase/sync_candidates.dart';
import 'package:x_scout_manager/features/candidates/vm/candidate_list_vm.dart';
import 'package:x_scout_manager/features/send_queue/data/send_queue_functions_repository.dart';
import 'package:x_scout_manager/features/send_queue/usecase/create_send_queue.dart';
import 'package:x_scout_manager/features/settings/data/settings_repository.dart';
import 'package:x_scout_manager/features/settings/model/scout_settings.dart';
import 'package:x_scout_manager/features/settings/model/tag_setting.dart';
import 'package:x_scout_manager/features/settings/usecase/load_scout_settings.dart';
import 'package:x_scout_manager/features/settings/usecase/save_scout_settings.dart';

void main() {
  test('複数選択した候補IDを送信キュー作成へ渡す', () async {
    final candidates = [
      _candidate('candidate-a'),
      _candidate('candidate-b'),
      _candidate('candidate-sent', status: CandidateStatus.sent, isSent: true),
    ];
    final sendQueueRepository = _RecordingSendQueueFunctionsRepository();
    final vm = _createVm(
      candidates: candidates,
      sendQueueFunctionsRepository: sendQueueRepository,
    );
    addTearDown(vm.dispose);

    await Future<void>.delayed(Duration.zero);

    vm.toggleSelection(candidates[0], true);
    vm.toggleSelection(candidates[1], true);
    vm.toggleSelection(candidates[2], true);

    expect(vm.state.selectedCandidateIds, {'candidate-a', 'candidate-b'});

    final queueId = await vm.createQueue();

    expect(queueId, 'queue-id');
    expect(sendQueueRepository.calls, [
      ['candidate-a', 'candidate-b'],
    ]);
    expect(vm.state.selectedCandidateIds, isEmpty);
    expect(vm.state.noticeMessage, '送信キューを作成しました。');
  });
}

CandidateListVm _createVm({
  required List<Candidate> candidates,
  required SendQueueFunctionsRepository sendQueueFunctionsRepository,
}) {
  final candidateRepository = _FakeCandidateRepository(candidates);
  final candidateFunctionsRepository = _FakeCandidateFunctionsRepository();
  final settingsRepository = _FakeSettingsRepository();

  return CandidateListVm(
    LoadCandidates(candidateRepository),
    CreateSendQueue(sendQueueFunctionsRepository),
    SyncCandidates(candidateFunctionsRepository),
    LoadCandidateSyncRuns(candidateRepository),
    RevertCandidateSyncRun(candidateFunctionsRepository),
    CleanupRevertedCandidates(candidateFunctionsRepository),
    LoadScoutSettings(settingsRepository),
    SaveScoutSettings(settingsRepository),
  );
}

Candidate _candidate(
  String candidateId, {
  CandidateStatus status = CandidateStatus.candidate,
  bool isExcluded = false,
  bool isSent = false,
}) {
  return Candidate(
    candidateId: candidateId,
    xUserId: candidateId,
    username: candidateId,
    sourceTags: const ['#test'],
    status: status,
    isExcluded: isExcluded,
    isSent: isSent,
  );
}

class _FakeCandidateRepository implements CandidateRepository {
  const _FakeCandidateRepository(this._candidates);

  final List<Candidate> _candidates;

  @override
  Stream<List<Candidate>> watchCandidates() {
    return Stream.value(_candidates);
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
      skippedExistingExcludedCount: 0,
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

class _RecordingSendQueueFunctionsRepository
    implements SendQueueFunctionsRepository {
  final calls = <List<String>>[];

  @override
  Future<String> createSendQueue(List<String> candidateIds) async {
    calls.add([...candidateIds]);
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
