import 'package:flutter/foundation.dart';

import '../model/dashboard_summary.dart';
import '../usecase/load_dashboard_summary.dart';

class DashboardState {
  const DashboardState({
    this.summary,
    this.isLoading = true,
    this.errorMessage,
  });

  final DashboardSummary? summary;
  final bool isLoading;
  final String? errorMessage;
}

class DashboardVm extends ChangeNotifier {
  DashboardVm(this._loadDashboardSummary) {
    load();
  }

  final LoadDashboardSummary _loadDashboardSummary;

  DashboardState _state = const DashboardState();

  DashboardState get state => _state;

  Future<void> load() async {
    _state = DashboardState(summary: _state.summary);
    notifyListeners();

    try {
      final summary = await _loadDashboardSummary();
      _state = DashboardState(summary: summary, isLoading: false);
      notifyListeners();
    } catch (_) {
      _state = const DashboardState(
        isLoading: false,
        errorMessage: 'ダッシュボードの読み込みに失敗しました。',
      );
      notifyListeners();
    }
  }
}
