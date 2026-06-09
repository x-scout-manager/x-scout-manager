import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../histories/model/send_history.dart';
import '../../histories/usecase/load_send_histories.dart';
import '../usecase/create_conversion.dart';

class ConversionFormState {
  const ConversionFormState({
    this.histories = const [],
    this.selectedHistoryId,
    this.salesAmountText = '',
    this.evidenceNote = '',
    this.isLoading = true,
    this.isSubmitting = false,
    this.errorMessage,
    this.noticeMessage,
  });

  final List<SendHistory> histories;
  final String? selectedHistoryId;
  final String salesAmountText;
  final String evidenceNote;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? noticeMessage;

  SendHistory? get selectedHistory {
    for (final history in histories) {
      if (history.historyId == selectedHistoryId) {
        return history;
      }
    }
    return null;
  }

  num? get salesAmount => num.tryParse(salesAmountText);
}

class ConversionFormVm extends ChangeNotifier {
  ConversionFormVm(this._loadSendHistories, this._createConversion) {
    _historySubscription = _loadSendHistories().listen(
      (histories) {
        _state = ConversionFormState(
          histories: histories,
          selectedHistoryId:
              _state.selectedHistoryId ??
              (histories.isNotEmpty ? histories.first.historyId : null),
          salesAmountText: _state.salesAmountText,
          evidenceNote: _state.evidenceNote,
          isLoading: false,
          noticeMessage: _state.noticeMessage,
        );
        notifyListeners();
      },
      onError: (_) {
        _state = const ConversionFormState(
          isLoading: false,
          errorMessage: '送信履歴の読み込みに失敗しました。',
        );
        notifyListeners();
      },
    );
  }

  final LoadSendHistories _loadSendHistories;
  final CreateConversion _createConversion;
  late final StreamSubscription<List<SendHistory>> _historySubscription;

  ConversionFormState _state = const ConversionFormState();

  ConversionFormState get state => _state;

  void selectHistory(String? historyId) {
    _state = _copyState(selectedHistoryId: historyId);
    notifyListeners();
  }

  void changeSalesAmount(String value) {
    _state = _copyState(salesAmountText: value);
    notifyListeners();
  }

  void changeEvidenceNote(String value) {
    _state = _copyState(evidenceNote: value);
    notifyListeners();
  }

  Future<void> submit() async {
    final historyId = _state.selectedHistoryId;
    final salesAmount = _state.salesAmount;

    if (historyId == null || historyId.isEmpty) {
      _state = _copyState(errorMessage: '送信履歴を選択してください。');
      notifyListeners();
      return;
    }

    if (salesAmount == null || salesAmount <= 0) {
      _state = _copyState(errorMessage: '対象売上を入力してください。');
      notifyListeners();
      return;
    }

    _state = _copyState(isSubmitting: true);
    notifyListeners();

    try {
      await _createConversion(
        sendHistoryId: historyId,
        salesAmount: salesAmount,
        evidenceNote: _state.evidenceNote,
      );
      _state = ConversionFormState(
        histories: _state.histories,
        selectedHistoryId: _state.selectedHistoryId,
        isLoading: false,
        noticeMessage: '成約記録を登録しました。',
      );
      notifyListeners();
    } on AppError catch (error) {
      _state = _copyState(isSubmitting: false, errorMessage: error.message);
      notifyListeners();
    } catch (_) {
      _state = _copyState(isSubmitting: false, errorMessage: '成約記録の登録に失敗しました。');
      notifyListeners();
    }
  }

  ConversionFormState _copyState({
    String? selectedHistoryId,
    String? salesAmountText,
    String? evidenceNote,
    bool? isSubmitting,
    String? errorMessage,
    String? noticeMessage,
  }) {
    return ConversionFormState(
      histories: _state.histories,
      selectedHistoryId: selectedHistoryId ?? _state.selectedHistoryId,
      salesAmountText: salesAmountText ?? _state.salesAmountText,
      evidenceNote: evidenceNote ?? _state.evidenceNote,
      isLoading: false,
      isSubmitting: isSubmitting ?? false,
      errorMessage: errorMessage,
      noticeMessage: noticeMessage,
    );
  }

  @override
  void dispose() {
    _historySubscription.cancel();
    super.dispose();
  }
}
