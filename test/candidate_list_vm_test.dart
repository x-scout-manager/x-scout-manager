import 'package:flutter_test/flutter_test.dart';
import 'package:x_scout_manager/features/candidates/data/candidate_functions_repository.dart';
import 'package:x_scout_manager/features/candidates/data/candidate_repository.dart';
import 'package:x_scout_manager/features/candidates/model/candidate.dart';
import 'package:x_scout_manager/features/candidates/model/candidate_page.dart';
import 'package:x_scout_manager/features/candidates/model/candidate_status.dart';
import 'package:x_scout_manager/features/candidates/model/candidate_sync_run.dart';
import 'package:x_scout_manager/features/candidates/usecase/cleanup_reverted_candidates.dart';
import 'package:x_scout_manager/features/candidates/usecase/load_candidate_sync_runs.dart';
import 'package:x_scout_manager/features/candidates/usecase/load_candidate_page.dart';
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

  test('50件単位で次ページを取得しページをまたいで選択を維持する', () async {
    final firstPageCandidates = [
      _candidate('candidate-a'),
      _candidate('candidate-b'),
    ];
    final secondPageCandidates = [_candidate('candidate-c')];
    final candidateRepository = _FakeCandidateRepository.pages([
      firstPageCandidates,
      secondPageCandidates,
    ]);
    final sendQueueRepository = _RecordingSendQueueFunctionsRepository();
    final vm = _createVm(
      candidates: const [],
      candidateRepository: candidateRepository,
      sendQueueFunctionsRepository: sendQueueRepository,
    );
    addTearDown(vm.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(vm.state.candidates, firstPageCandidates);
    expect(vm.state.pageNumber, 1);
    expect(vm.state.hasNextPage, isTrue);
    expect(candidateRepository.requestedPageSizes, [50]);

    vm.toggleSelection(firstPageCandidates.first, true);
    await vm.goToNextPage();

    expect(vm.state.candidates, secondPageCandidates);
    expect(vm.state.pageNumber, 2);
    expect(vm.state.hasNextPage, isFalse);
    expect(vm.state.selectedCandidateIds, {'candidate-a'});
    expect(candidateRepository.requestedPageSizes, [50, 50]);

    await vm.goToPreviousPage();

    expect(vm.state.candidates, firstPageCandidates);
    expect(vm.state.pageNumber, 1);
    expect(vm.state.selectedCandidateIds, {'candidate-a'});
  });

  test('候補抽出後に先頭ページを再取得する', () async {
    final candidateRepository = _FakeCandidateRepository.pages([
      [_candidate('candidate-a')],
      [_candidate('candidate-b')],
    ]);
    final vm = _createVm(
      candidates: const [],
      candidateRepository: candidateRepository,
      sendQueueFunctionsRepository: _RecordingSendQueueFunctionsRepository(),
    );
    addTearDown(vm.dispose);

    await Future<void>.delayed(Duration.zero);
    await vm.goToNextPage();

    expect(vm.state.pageNumber, 2);

    await vm.syncCandidates();

    expect(vm.state.pageNumber, 1);
    expect(vm.state.candidates.single.candidateId, 'candidate-a');
    expect(candidateRepository.requestedStartAfterIds, [
      null,
      'candidate-a',
      null,
    ]);
  });
}

CandidateListVm _createVm({
  required List<Candidate> candidates,
  CandidateRepository? candidateRepository,
  required SendQueueFunctionsRepository sendQueueFunctionsRepository,
}) {
  final resolvedCandidateRepository =
      candidateRepository ?? _FakeCandidateRepository(candidates);
  final candidateFunctionsRepository = _FakeCandidateFunctionsRepository();
  final settingsRepository = _FakeSettingsRepository();

  return CandidateListVm(
    LoadCandidatePage(resolvedCandidateRepository),
    CreateSendQueue(sendQueueFunctionsRepository),
    SyncCandidates(candidateFunctionsRepository),
    LoadCandidateSyncRuns(resolvedCandidateRepository),
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
  _FakeCandidateRepository(List<Candidate> candidates) : _pages = [candidates];

  _FakeCandidateRepository.pages(this._pages);

  final List<List<Candidate>> _pages;
  final Map<String, int> _pageIndexByCursorId = {};
  final List<int> requestedPageSizes = [];
  final List<String?> requestedStartAfterIds = [];

  @override
  Future<CandidatePage> loadCandidatePage({
    CandidatePageCursor? startAfter,
    int pageSize = 50,
  }) async {
    requestedPageSizes.add(pageSize);
    requestedStartAfterIds.add(startAfter?.candidateId);
    final pageIndex = startAfter == null
        ? 0
        : _pageIndexByCursorId[startAfter.candidateId] ?? 0;
    final candidates = _pages[pageIndex];
    CandidatePageCursor? nextCursor;
    if (pageIndex + 1 < _pages.length && candidates.isNotEmpty) {
      final lastCandidate = candidates.last;
      _pageIndexByCursorId[lastCandidate.candidateId] = pageIndex + 1;
      nextCursor = CandidatePageCursor(
        candidateId: lastCandidate.candidateId,
        status: lastCandidate.status.name,
        updatedAt: DateTime(2026),
      );
    }
    return CandidatePage(candidates: candidates, nextCursor: nextCursor);
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
