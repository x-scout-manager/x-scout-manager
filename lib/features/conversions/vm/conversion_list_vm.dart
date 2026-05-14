import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/conversion.dart';
import '../usecase/load_conversions.dart';

class ConversionListState {
  const ConversionListState({
    this.conversions = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  final List<Conversion> conversions;
  final bool isLoading;
  final String? errorMessage;
}

class ConversionListVm extends ChangeNotifier {
  ConversionListVm(this._loadConversions) {
    _subscription = _loadConversions().listen(
      (conversions) {
        _state = ConversionListState(
          conversions: conversions,
          isLoading: false,
        );
        notifyListeners();
      },
      onError: (_) {
        _state = const ConversionListState(
          isLoading: false,
          errorMessage: '成果一覧の読み込みに失敗しました。',
        );
        notifyListeners();
      },
    );
  }

  final LoadConversions _loadConversions;
  late final StreamSubscription<List<Conversion>> _subscription;

  ConversionListState _state = const ConversionListState();

  ConversionListState get state => _state;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
