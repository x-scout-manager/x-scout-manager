import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../settings/model/scout_settings.dart';
import '../../settings/usecase/load_scout_settings.dart';
import '../../settings/usecase/save_scout_settings.dart';
import '../data/candidate_functions_repository.dart';
import '../model/candidate.dart';
import '../model/candidate_page.dart';
import '../model/candidate_sync_run.dart';
import '../usecase/cleanup_reverted_candidates.dart';
import '../usecase/load_candidate_page.dart';
import '../usecase/load_candidate_sync_runs.dart';
import '../usecase/revert_candidate_sync_run.dart';
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
    this.isCleaningRevertedCandidates = false,
    this.isSavingSearchMode = false,
    this.isLoadingPage = false,
    this.pageNumber = 1,
    this.hasNextPage = false,
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
  final bool isCleaningRevertedCandidates;
  final bool isSavingSearchMode;
  final bool isLoadingPage;
  final int pageNumber;
  final bool hasNextPage;
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
    bool? isCleaningRevertedCandidates,
    bool? isSavingSearchMode,
    bool? isLoadingPage,
    int? pageNumber,
    bool? hasNextPage,
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
      isCleaningRevertedCandidates:
          isCleaningRevertedCandidates ?? this.isCleaningRevertedCandidates,
      isSavingSearchMode: isSavingSearchMode ?? this.isSavingSearchMode,
      isLoadingPage: isLoadingPage ?? this.isLoadingPage,
      pageNumber: pageNumber ?? this.pageNumber,
      hasNextPage: hasNextPage ?? this.hasNextPage,
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
    this._loadCandidatePage,
    this._createSendQueue,
    this._syncCandidates,
    this._loadCandidateSyncRuns,
    this._revertCandidateSyncRun,
    this._cleanupRevertedCandidates,
    this._loadScoutSettings,
    this._saveScoutSettings,
  ) {
    unawaited(_loadPage(0));
    _settingsSubscription = _loadScoutSettings().listen(
      (settings) {
        if (_isDisposed) {
          return;
        }
        _state = _state.copyWith(
          settings: settings ?? ScoutSettings.defaults,
          clearErrorMessage: true,
        );
        notifyListeners();
      },
      onError: (_) {
        if (_isDisposed) {
          return;
        }
        _state = _state.copyWith(errorMessage: '抽出設定の読み込みに失敗しました。');
        notifyListeners();
      },
    );
    _syncRunsSubscription = _loadCandidateSyncRuns().listen(
      (runs) {
        if (_isDisposed) {
          return;
        }
        _state = _state.copyWith(syncRuns: runs);
        notifyListeners();
      },
      onError: (_) {
        if (_isDisposed) {
          return;
        }
        _state = _state.copyWith(errorMessage: '抽出履歴の読み込みに失敗しました。');
        notifyListeners();
      },
    );
  }

  static const pageSize = 50;

  final LoadCandidatePage _loadCandidatePage;
  final CreateSendQueue _createSendQueue;
  final SyncCandidates _syncCandidates;
  final LoadCandidateSyncRuns _loadCandidateSyncRuns;
  final RevertCandidateSyncRun _revertCandidateSyncRun;
  final CleanupRevertedCandidates _cleanupRevertedCandidates;
  final LoadScoutSettings _loadScoutSettings;
  final SaveScoutSettings _saveScoutSettings;
  late final StreamSubscription _settingsSubscription;
  late final StreamSubscription _syncRunsSubscription;
  final List<CandidatePageCursor?> _pageCursors = [null];
  bool _isDisposed = false;

  CandidateListState _state = const CandidateListState();

  CandidateListState get state => _state;

  bool get canGoToPreviousPage =>
      _state.pageNumber > 1 && !_state.isLoadingPage;

  bool get canGoToNextPage => _state.hasNextPage && !_state.isLoadingPage;

  Future<void> goToPreviousPage() async {
    if (!canGoToPreviousPage) {
      return;
    }
    await _loadPage(_state.pageNumber - 2);
  }

  Future<void> goToNextPage() async {
    if (!canGoToNextPage) {
      return;
    }
    await _loadPage(_state.pageNumber);
  }

  Future<void> refreshFirstPage() async {
    _pageCursors
      ..clear()
      ..add(null);
    await _loadPage(0);
  }

  Future<void> _loadPage(int pageIndex) async {
    if (_state.isLoadingPage ||
        pageIndex < 0 ||
        pageIndex >= _pageCursors.length) {
      return;
    }

    _state = _state.copyWith(isLoadingPage: true, clearErrorMessage: true);
    notifyListeners();

    try {
      final page = await _loadCandidatePage(
        startAfter: _pageCursors[pageIndex],
        pageSize: pageSize,
      );
      if (_isDisposed) {
        return;
      }
      _setNextPageCursor(pageIndex, page.nextCursor);
      _state = _state.copyWith(
        candidates: page.candidates,
        isLoading: false,
        isLoadingPage: false,
        pageNumber: pageIndex + 1,
        hasNextPage: page.hasNextPage,
      );
      notifyListeners();
    } catch (_) {
      if (_isDisposed) {
        return;
      }
      _state = _state.copyWith(
        isLoading: false,
        isLoadingPage: false,
        errorMessage: '候補一覧の読み込みに失敗しました。',
      );
      notifyListeners();
    }
  }

  void _setNextPageCursor(int pageIndex, CandidatePageCursor? nextCursor) {
    final nextIndex = pageIndex + 1;
    if (_pageCursors.length > nextIndex) {
      _pageCursors.removeRange(nextIndex, _pageCursors.length);
    }
    if (nextCursor != null) {
      _pageCursors.add(nextCursor);
    }
  }

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
        noticeMessage: _syncNotice(result),
      );
      notifyListeners();
      await refreshFirstPage();
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

  String _syncNotice(SyncCandidatesResult result) {
    return '候補抽出が完了しました。'
        '新規${result.createdCount}件、'
        '更新${result.updatedCount}件、'
        '除外${result.excludedCount}件、'
        '除外済みでスキップ${result.skippedExistingExcludedCount}件。';
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
      await refreshFirstPage();
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

  Future<void> cleanupRevertedCandidates() async {
    if (_state.isCleaningRevertedCandidates) {
      return;
    }

    _state = _state.copyWith(
      isCleaningRevertedCandidates: true,
      clearErrorMessage: true,
      clearNoticeMessage: true,
    );
    notifyListeners();

    try {
      final result = await _cleanupRevertedCandidates();
      _state = _state.copyWith(
        isCleaningRevertedCandidates: false,
        noticeMessage: _cleanupNotice(result),
      );
      notifyListeners();
      await refreshFirstPage();
    } on AppError catch (error) {
      _state = _state.copyWith(
        isCleaningRevertedCandidates: false,
        errorMessage: error.message,
      );
      notifyListeners();
    } catch (_) {
      _state = _state.copyWith(
        isCleaningRevertedCandidates: false,
        errorMessage: '解除済み候補の再掃除に失敗しました。',
      );
      notifyListeners();
    }
  }

  String _cleanupNotice(CleanupRevertedCandidatesResult result) {
    final base =
        '解除済み候補を再掃除しました。復元${result.restoredCount}件、削除${result.deletedCount}件、スキップ${result.skippedCount}件。';
    if (result.skippedReasons.isEmpty) {
      return base;
    }
    final reasons = result.skippedReasons.entries
        .map((entry) => '${_skipReasonLabel(entry.key)}${entry.value}件')
        .join('、');
    return '$base スキップ理由: $reasons。';
  }

  String _skipReasonLabel(String reason) {
    return switch (reason) {
      'sent_history_exists' => '送信履歴あり',
      'send_queue_item_exists' => '送信キュー明細あり',
      'last_sync_run_missing' => '最終抽出IDなし',
      'active_sync_run_exists' => '未解除の抽出あり',
      'sync_change_missing' => '抽出差分なし',
      'sync_run_cycle' => '抽出履歴循環',
      'sync_run_chain_too_deep' => '抽出履歴が深すぎる',
      _ => '$reason ',
    };
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
    _isDisposed = true;
    _settingsSubscription.cancel();
    _syncRunsSubscription.cancel();
    super.dispose();
  }
}
