import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/send_queue.dart';
import '../usecase/load_send_queues.dart';

class SendQueueListState {
  const SendQueueListState({
    this.queues = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  final List<SendQueue> queues;
  final bool isLoading;
  final String? errorMessage;
}

class SendQueueListVm extends ChangeNotifier {
  SendQueueListVm(this._loadSendQueues) {
    _subscription = _loadSendQueues().listen(
      (queues) {
        _state = SendQueueListState(queues: queues, isLoading: false);
        notifyListeners();
      },
      onError: (_) {
        _state = const SendQueueListState(
          isLoading: false,
          errorMessage: '送信キュー一覧の読み込みに失敗しました。',
        );
        notifyListeners();
      },
    );
  }

  final LoadSendQueues _loadSendQueues;
  late final StreamSubscription<List<SendQueue>> _subscription;

  SendQueueListState _state = const SendQueueListState();

  SendQueueListState get state => _state;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
