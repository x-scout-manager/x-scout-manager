import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../histories/model/send_history.dart';
import '../../histories/usecase/load_send_histories.dart';
import '../../settings/model/scout_settings.dart';
import '../../settings/usecase/load_scout_settings.dart';
import '../usecase/create_conversion.dart';

class ConversionFormState {
  const ConversionFormState({
    this.histories = const [],
    this.selectedHistoryId,
    this.salesAmountText = '',
    this.rewardRateText = '',
    this.evidenceNote = '',
    this.isLoading = true,
    this.isSubmitting = false,
    this.errorMessage,
    this.noticeMessage,
  });

  final List<SendHistory> histories;
  final String? selectedHistoryId;
  final String salesAmountText;
  final String rewardRateText;
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

  num? get rewardRate => num.tryParse(rewardRateText);

  num? get rewardAmount {
    final sales = salesAmount;
    final rate = rewardRate;
    if (sales == null || sales <= 0 || rate == null || rate <= 0) {
      return null;
    }
    return (sales * rate).round();
  }
}

class ConversionFormVm extends ChangeNotifier {
  ConversionFormVm(
    this._loadSendHistories,
    this._loadScoutSettings,
    this._createConversion,
  ) {
    _historySubscription = _loadSendHistories().listen(
      (histories) {
        _state = ConversionFormState(
          histories: histories,
          selectedHistoryId:
              _state.selectedHistoryId ??
              (histories.isNotEmpty ? histories.first.historyId : null),
          salesAmountText: _state.salesAmountText,
          rewardRateText: _state.rewardRateText,
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
    _settingsSubscription = _loadScoutSettings().listen((settings) {
      final rewardRate =
          settings?.defaultRewardRate ??
          ScoutSettings.defaults.defaultRewardRate;
      if (_state.rewardRateText.isNotEmpty) {
        return;
      }
      _state = ConversionFormState(
        histories: _state.histories,
        selectedHistoryId: _state.selectedHistoryId,
        salesAmountText: _state.salesAmountText,
        rewardRateText: rewardRate.toString(),
        evidenceNote: _state.evidenceNote,
        isLoading: _state.isLoading,
      );
      notifyListeners();
    });
  }

  final LoadSendHistories _loadSendHistories;
  final LoadScoutSettings _loadScoutSettings;
  final CreateConversion _createConversion;
  late final StreamSubscription<List<SendHistory>> _historySubscription;
  late final StreamSubscription<ScoutSettings?> _settingsSubscription;

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

  void changeRewardRate(String value) {
    _state = _copyState(rewardRateText: value);
    notifyListeners();
  }

  void changeEvidenceNote(String value) {
    _state = _copyState(evidenceNote: value);
    notifyListeners();
  }

  Future<void> submit() async {
    final historyId = _state.selectedHistoryId;
    final salesAmount = _state.salesAmount;
    final rewardRate = _state.rewardRate;

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

    if (rewardRate == null || rewardRate <= 0) {
      _state = _copyState(errorMessage: '成果報酬率を入力してください。');
      notifyListeners();
      return;
    }

    _state = _copyState(isSubmitting: true);
    notifyListeners();

    try {
      await _createConversion(
        sendHistoryId: historyId,
        salesAmount: salesAmount,
        rewardRate: rewardRate,
        evidenceNote: _state.evidenceNote,
      );
      _state = ConversionFormState(
        histories: _state.histories,
        selectedHistoryId: _state.selectedHistoryId,
        rewardRateText: _state.rewardRateText,
        isLoading: false,
        noticeMessage: '成果証跡を登録しました。',
      );
      notifyListeners();
    } on AppError catch (error) {
      _state = _copyState(isSubmitting: false, errorMessage: error.message);
      notifyListeners();
    } catch (_) {
      _state = _copyState(isSubmitting: false, errorMessage: '成果証跡の登録に失敗しました。');
      notifyListeners();
    }
  }

  ConversionFormState _copyState({
    String? selectedHistoryId,
    String? salesAmountText,
    String? rewardRateText,
    String? evidenceNote,
    bool? isSubmitting,
    String? errorMessage,
    String? noticeMessage,
  }) {
    return ConversionFormState(
      histories: _state.histories,
      selectedHistoryId: selectedHistoryId ?? _state.selectedHistoryId,
      salesAmountText: salesAmountText ?? _state.salesAmountText,
      rewardRateText: rewardRateText ?? _state.rewardRateText,
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
    _settingsSubscription.cancel();
    super.dispose();
  }
}
