import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/candidate.dart';
import '../usecase/load_candidates.dart';

class CandidateListState {
  const CandidateListState({
    this.candidates = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  final List<Candidate> candidates;
  final bool isLoading;
  final String? errorMessage;
}

class CandidateListVm extends ChangeNotifier {
  CandidateListVm(this._loadCandidates) {
    _subscription = _loadCandidates().listen(
      (candidates) {
        _state = CandidateListState(candidates: candidates, isLoading: false);
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
  late final StreamSubscription _subscription;

  CandidateListState _state = const CandidateListState();

  CandidateListState get state => _state;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
