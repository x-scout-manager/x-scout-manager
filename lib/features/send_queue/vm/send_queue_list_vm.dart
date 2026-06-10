import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/send_queue.dart';
import '../usecase/load_send_queues.dart';

class SendQueueListState {
  const SendQueueListState({
    this.queues = const [],
    this.showCompletedQueues = false,
    this.hasHiddenCompletedQueues = false,
    this.isLoading = true,
    this.errorMessage,
  });

  final List<SendQueue> queues;
  final bool showCompletedQueues;
  final bool hasHiddenCompletedQueues;
  final bool isLoading;
  final String? errorMessage;
}

class SendQueueListVm extends ChangeNotifier {
  SendQueueListVm(this._loadSendQueues) {
    _subscription = _loadSendQueues().listen(
      (queues) {
        _allQueues = queues;
        _state = _buildState(isLoading: false);
        notifyListeners();
      },
      onError: (_) {
        _state = SendQueueListState(
          showCompletedQueues: _showCompletedQueues,
          isLoading: false,
          errorMessage: '送信キュー一覧の読み込みに失敗しました。',
        );
        notifyListeners();
      },
    );
  }

  final LoadSendQueues _loadSendQueues;
  late final StreamSubscription<List<SendQueue>> _subscription;

  List<SendQueue> _allQueues = const [];
  bool _showCompletedQueues = false;
  SendQueueListState _state = const SendQueueListState();

  SendQueueListState get state => _state;

  void setShowCompletedQueues(bool value) {
    if (_showCompletedQueues == value) {
      return;
    }
    _showCompletedQueues = value;
    _state = _buildState(isLoading: false);
    notifyListeners();
  }

  SendQueueListState _buildState({required bool isLoading}) {
    final visibleQueues = _showCompletedQueues
        ? _allQueues
        : _allQueues.where((queue) => !queue.isCompleted).toList();
    return SendQueueListState(
      queues: visibleQueues,
      showCompletedQueues: _showCompletedQueues,
      hasHiddenCompletedQueues: _allQueues.any((queue) => queue.isCompleted),
      isLoading: isLoading,
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
