import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../settings/model/scout_settings.dart';
import '../../settings/usecase/load_scout_settings.dart';
import '../../settings/usecase/save_scout_settings.dart';
import '../model/candidate.dart';
import '../model/candidate_sync_run.dart';
import '../usecase/load_candidate_sync_runs.dart';
import '../usecase/revert_candidate_sync_run.dart';
import '../usecase/load_candidates.dart';
import '../usecase/sync_candidates.dart';
import '../../send_queue/usecase/create_send_queue.dart';

class CandidateListState {
  const CandidateListState({
    this.candidates = const [],
    this.selectedCandidateIds = const {},
    this.isLoading = true,
    this.isCreatingQueue = false,
    this.isSyncing = false,
    this.isRevertingSyncRun = false,
    this.isSavingSearchMode = false,
    this.settings = ScoutSettings.defaults,
    this.syncRuns = const [],
    this.errorMessage,
    this.noticeMessage,
  });

  final List<Candidate> candidates;
  final Set<String> selectedCandidateIds;
  final bool isLoading;
  final bool isCreatingQueue;
  final bool isSyncing;
  final bool isRevertingSyncRun;
  final bool isSavingSearchMode;
  final ScoutSettings settings;
  final List<CandidateSyncRun> syncRuns;
  final String? errorMessage;
  final String? noticeMessage;

  CandidateListState copyWith({
    List<Candidate>? candidates,
    Set<String>? selectedCandidateIds,
    bool? isLoading,
    bool? isCreatingQueue,
    bool? isSyncing,
    bool? isRevertingSyncRun,
    bool? isSavingSearchMode,
    ScoutSettings? settings,
    List<CandidateSyncRun>? syncRuns,
    String? errorMessage,
    String? noticeMessage,
    bool clearErrorMessage = false,
    bool clearNoticeMessage = false,
  }) {
    return CandidateListState(
      candidates: candidates ?? this.candidates,
      selectedCandidateIds: selectedCandidateIds ?? this.selectedCandidateIds,
      isLoading: isLoading ?? this.isLoading,
      isCreatingQueue: isCreatingQueue ?? this.isCreatingQueue,
      isSyncing: isSyncing ?? this.isSyncing,
      isRevertingSyncRun: isRevertingSyncRun ?? this.isRevertingSyncRun,
      isSavingSearchMode: isSavingSearchMode ?? this.isSavingSearchMode,
      settings: settings ?? this.settings,
      syncRuns: syncRuns ?? this.syncRuns,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      noticeMessage: clearNoticeMessage
          ? null
          : noticeMessage ?? this.noticeMessage,
    );
  }
}

class CandidateListVm extends ChangeNotifier {
  CandidateListVm(
    this._loadCandidates,
    this._createSendQueue,
    this._syncCandidates,
    this._loadCandidateSyncRuns,
    this._revertCandidateSyncRun,
    this._loadScoutSettings,
    this._saveScoutSettings,
  ) {
    _candidateSubscription = _loadCandidates().listen(
      (candidates) {
        final candidateIds = candidates
            .map((candidate) => candidate.candidateId)
            .toSet();
        _state = _state.copyWith(
          candidates: candidates,
          selectedCandidateIds: _state.selectedCandidateIds
              .where(candidateIds.contains)
              .toSet(),
          isLoading: false,
          clearErrorMessage: true,
        );
        notifyListeners();
      },
      onError: (_) {
        _state = _state.copyWith(
          isLoading: false,
          errorMessage: '候補一覧の読み込みに失敗しました。',
        );
        notifyListeners();
      },
    );
    _settingsSubscription = _loadScoutSettings().listen(
      (settings) {
        _state = _state.copyWith(
          settings: settings ?? ScoutSettings.defaults,
          clearErrorMessage: true,
        );
        notifyListeners();
      },
      onError: (_) {
        _state = _state.copyWith(errorMessage: '抽出設定の読み込みに失敗しました。');
        notifyListeners();
      },
    );
    _syncRunsSubscription = _loadCandidateSyncRuns().listen(
      (runs) {
        _state = _state.copyWith(syncRuns: runs);
        notifyListeners();
      },
      onError: (_) {
        _state = _state.copyWith(errorMessage: '抽出履歴の読み込みに失敗しました。');
        notifyListeners();
      },
    );
  }

  final LoadCandidates _loadCandidates;
  final CreateSendQueue _createSendQueue;
  final SyncCandidates _syncCandidates;
  final LoadCandidateSyncRuns _loadCandidateSyncRuns;
  final RevertCandidateSyncRun _revertCandidateSyncRun;
  final LoadScoutSettings _loadScoutSettings;
  final SaveScoutSettings _saveScoutSettings;
  late final StreamSubscription _candidateSubscription;
  late final StreamSubscription _settingsSubscription;
  late final StreamSubscription _syncRunsSubscription;

  CandidateListState _state = const CandidateListState();

  CandidateListState get state => _state;

  void toggleSelection(Candidate candidate, bool selected) {
    if (!candidate.canSend) {
      return;
    }

    final selectedCandidateIds = {..._state.selectedCandidateIds};
    if (selected) {
      selectedCandidateIds.add(candidate.candidateId);
    } else {
      selectedCandidateIds.remove(candidate.candidateId);
    }

    _state = _state.copyWith(
      selectedCandidateIds: selectedCandidateIds,
      isLoading: false,
      clearErrorMessage: true,
      clearNoticeMessage: true,
    );
    notifyListeners();
  }

  Future<void> changeTagSearchMode(TagSearchMode mode) async {
    if (_state.settings.tagSearchMode == mode || _state.isSavingSearchMode) {
      return;
    }

    final previousSettings = _state.settings;
    final nextSettings = previousSettings.copyWith(tagSearchMode: mode);
    _state = _state.copyWith(
      settings: nextSettings,
      isSavingSearchMode: true,
      clearErrorMessage: true,
      clearNoticeMessage: true,
    );
    notifyListeners();

    try {
      await _saveScoutSettings(nextSettings);
      _state = _state.copyWith(
        isSavingSearchMode: false,
        noticeMessage: 'タグ検索モードを保存しました。',
      );
      notifyListeners();
    } catch (_) {
      _state = _state.copyWith(
        settings: previousSettings,
        isSavingSearchMode: false,
        errorMessage: 'タグ検索モードの保存に失敗しました。',
      );
      notifyListeners();
    }
  }

  Future<void> syncCandidates() async {
    _state = _state.copyWith(
      isLoading: false,
      isSyncing: true,
      clearErrorMessage: true,
      clearNoticeMessage: true,
    );
    notifyListeners();

    try {
      final result = await _syncCandidates();
      _state = _state.copyWith(
        isLoading: false,
        isSyncing: false,
        noticeMessage:
            '候補抽出が完了しました。新規${result.createdCount}件、更新${result.updatedCount}件、除外${result.excludedCount}件。',
      );
      notifyListeners();
    } on AppError catch (error) {
      _state = _state.copyWith(
        isLoading: false,
        isSyncing: false,
        errorMessage: error.message,
      );
      notifyListeners();
    } catch (_) {
      _state = _state.copyWith(
        isLoading: false,
        isSyncing: false,
        errorMessage: '候補抽出に失敗しました。',
      );
      notifyListeners();
    }
  }

  Future<void> revertSyncRun(String runId) async {
    if (_state.isRevertingSyncRun || runId.isEmpty) {
      return;
    }

    _state = _state.copyWith(
      isRevertingSyncRun: true,
      clearErrorMessage: true,
      clearNoticeMessage: true,
    );
    notifyListeners();

    try {
      final result = await _revertCandidateSyncRun(runId);
      _state = _state.copyWith(
        isRevertingSyncRun: false,
        noticeMessage:
            '抽出を解除しました。復元${result.revertedCount}件、削除${result.deletedCount}件、スキップ${result.skippedCount}件。',
      );
      notifyListeners();
    } on AppError catch (error) {
      _state = _state.copyWith(
        isRevertingSyncRun: false,
        errorMessage: error.message,
      );
      notifyListeners();
    } catch (_) {
      _state = _state.copyWith(
        isRevertingSyncRun: false,
        errorMessage: '抽出解除に失敗しました。',
      );
      notifyListeners();
    }
  }

  Future<String?> createQueue() async {
    if (_state.selectedCandidateIds.isEmpty) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: '送信キューに追加する候補を選択してください。',
      );
      notifyListeners();
      return null;
    }

    _state = _state.copyWith(
      isLoading: false,
      isCreatingQueue: true,
      clearErrorMessage: true,
      clearNoticeMessage: true,
    );
    notifyListeners();

    try {
      final queueId = await _createSendQueue(
        _state.selectedCandidateIds.toList(),
      );
      _state = _state.copyWith(
        isLoading: false,
        isCreatingQueue: false,
        selectedCandidateIds: const {},
        noticeMessage: '送信キューを作成しました。',
      );
      notifyListeners();
      return queueId;
    } on AppError catch (error) {
      _state = _state.copyWith(
        isLoading: false,
        isCreatingQueue: false,
        errorMessage: error.message,
      );
      notifyListeners();
      return null;
    } catch (_) {
      _state = _state.copyWith(
        isLoading: false,
        isCreatingQueue: false,
        errorMessage: '送信キューの作成に失敗しました。',
      );
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _candidateSubscription.cancel();
    _settingsSubscription.cancel();
    _syncRunsSubscription.cancel();
    super.dispose();
  }
}
