import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/send_history.dart';
import '../usecase/load_send_histories.dart';

class SendHistoryState {
  const SendHistoryState({
    this.histories = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  final List<SendHistory> histories;
  final bool isLoading;
  final String? errorMessage;
}

class SendHistoryVm extends ChangeNotifier {
  SendHistoryVm(this._loadSendHistories) {
    _subscription = _loadSendHistories().listen(
      (histories) {
        _state = SendHistoryState(histories: histories, isLoading: false);
        notifyListeners();
      },
      onError: (_) {
        _state = const SendHistoryState(
          isLoading: false,
          errorMessage: '送信履歴の読み込みに失敗しました。',
        );
        notifyListeners();
      },
    );
  }

  final LoadSendHistories _loadSendHistories;
  late final StreamSubscription<List<SendHistory>> _subscription;

  SendHistoryState _state = const SendHistoryState();

  SendHistoryState get state => _state;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
