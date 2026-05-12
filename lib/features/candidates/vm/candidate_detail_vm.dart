import 'package:flutter/foundation.dart';

import '../data/candidate_repository.dart';
import '../model/candidate.dart';

class CandidateDetailState {
  const CandidateDetailState({
    this.candidate,
    this.isLoading = true,
    this.errorMessage,
  });

  final Candidate? candidate;
  final bool isLoading;
  final String? errorMessage;
}

class CandidateDetailVm extends ChangeNotifier {
  CandidateDetailVm(this._repository, this._candidateId) {
    _load();
  }

  final CandidateRepository _repository;
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
}
