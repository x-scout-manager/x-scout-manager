import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../model/candidate.dart';
import '../usecase/load_candidates.dart';
import '../../send_queue/usecase/create_send_queue.dart';

class CandidateListState {
  const CandidateListState({
    this.candidates = const [],
    this.selectedCandidateIds = const {},
    this.isLoading = true,
    this.isCreatingQueue = false,
    this.errorMessage,
    this.noticeMessage,
  });

  final List<Candidate> candidates;
  final Set<String> selectedCandidateIds;
  final bool isLoading;
  final bool isCreatingQueue;
  final String? errorMessage;
  final String? noticeMessage;
}

class CandidateListVm extends ChangeNotifier {
  CandidateListVm(this._loadCandidates, this._createSendQueue) {
    _subscription = _loadCandidates().listen(
      (candidates) {
        final candidateIds = candidates
            .map((candidate) => candidate.candidateId)
            .toSet();
        _state = CandidateListState(
          candidates: candidates,
          selectedCandidateIds: _state.selectedCandidateIds
              .where(candidateIds.contains)
              .toSet(),
          isLoading: false,
        );
        notifyListeners();
      },
      onError: (_) {
        _state = const CandidateListState(
          isLoading: false,
          errorMessage: '候補一覧の読み込みに失敗しました。',
        );
        notifyListeners();
      },
    );
  }

  final LoadCandidates _loadCandidates;
  final CreateSendQueue _createSendQueue;
  late final StreamSubscription _subscription;

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

    _state = CandidateListState(
      candidates: _state.candidates,
      selectedCandidateIds: selectedCandidateIds,
      isLoading: false,
    );
    notifyListeners();
  }

  Future<String?> createQueue() async {
    if (_state.selectedCandidateIds.isEmpty) {
      _state = CandidateListState(
        candidates: _state.candidates,
        selectedCandidateIds: _state.selectedCandidateIds,
        isLoading: false,
        errorMessage: '送信キューに追加する候補を選択してください。',
      );
      notifyListeners();
      return null;
    }

    _state = CandidateListState(
      candidates: _state.candidates,
      selectedCandidateIds: _state.selectedCandidateIds,
      isLoading: false,
      isCreatingQueue: true,
    );
    notifyListeners();

    try {
      final queueId = await _createSendQueue(
        _state.selectedCandidateIds.toList(),
      );
      _state = CandidateListState(
        candidates: _state.candidates,
        isLoading: false,
        noticeMessage: '送信キューを作成しました。',
      );
      notifyListeners();
      return queueId;
    } on AppError catch (error) {
      _state = CandidateListState(
        candidates: _state.candidates,
        selectedCandidateIds: _state.selectedCandidateIds,
        isLoading: false,
        errorMessage: error.message,
      );
      notifyListeners();
      return null;
    } catch (_) {
      _state = CandidateListState(
        candidates: _state.candidates,
        selectedCandidateIds: _state.selectedCandidateIds,
        isLoading: false,
        errorMessage: '送信キューの作成に失敗しました。',
      );
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
