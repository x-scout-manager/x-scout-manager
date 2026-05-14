import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../data/candidate_repository.dart';
import '../model/candidate.dart';
import '../usecase/exclude_candidate.dart';
import '../usecase/restore_candidate.dart';

class CandidateDetailState {
  const CandidateDetailState({
    this.candidate,
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
    this.noticeMessage,
  });

  final Candidate? candidate;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? noticeMessage;
}

class CandidateDetailVm extends ChangeNotifier {
  CandidateDetailVm(
    this._repository,
    this._excludeCandidate,
    this._restoreCandidate,
    this._candidateId,
  ) {
    _load();
  }

  final CandidateRepository _repository;
  final ExcludeCandidate _excludeCandidate;
  final RestoreCandidate _restoreCandidate;
  final String _candidateId;

  CandidateDetailState _state = const CandidateDetailState();

  CandidateDetailState get state => _state;

  Future<void> _load() async {
    try {
      final candidate = await _repository.findById(_candidateId);
      _state = CandidateDetailState(candidate: candidate, isLoading: false);
      notifyListeners();
    } catch (_) {
      _state = const CandidateDetailState(
        isLoading: false,
        errorMessage: '候補詳細の読み込みに失敗しました。',
      );
      notifyListeners();
    }
  }

  Future<void> exclude({String? reason}) async {
    final candidate = _state.candidate;
    if (candidate == null) {
      return;
    }

    _state = CandidateDetailState(
      candidate: candidate,
      isLoading: false,
      isSaving: true,
    );
    notifyListeners();

    try {
      await _excludeCandidate(candidate.candidateId, reason: reason);
      final latest = await _repository.findById(_candidateId);
      _state = CandidateDetailState(
        candidate: latest,
        isLoading: false,
        noticeMessage: '除外リストに追加しました。',
      );
      notifyListeners();
    } on AppError catch (error) {
      _state = CandidateDetailState(
        candidate: candidate,
        isLoading: false,
        errorMessage: error.message,
      );
      notifyListeners();
    } catch (_) {
      _state = CandidateDetailState(
        candidate: candidate,
        isLoading: false,
        errorMessage: '除外リストへの追加に失敗しました。',
      );
      notifyListeners();
    }
  }

  Future<void> restore() async {
    final candidate = _state.candidate;
    if (candidate == null) {
      return;
    }

    _state = CandidateDetailState(
      candidate: candidate,
      isLoading: false,
      isSaving: true,
    );
    notifyListeners();

    try {
      await _restoreCandidate(candidate.candidateId);
      final latest = await _repository.findById(_candidateId);
      _state = CandidateDetailState(
        candidate: latest,
        isLoading: false,
        noticeMessage: '除外リストから戻しました。',
      );
      notifyListeners();
    } on AppError catch (error) {
      _state = CandidateDetailState(
        candidate: candidate,
        isLoading: false,
        errorMessage: error.message,
      );
      notifyListeners();
    } catch (_) {
      _state = CandidateDetailState(
        candidate: candidate,
        isLoading: false,
        errorMessage: '除外解除に失敗しました。',
      );
      notifyListeners();
    }
  }
}
