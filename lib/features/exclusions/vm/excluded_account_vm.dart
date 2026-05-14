import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../candidates/usecase/restore_candidate.dart';
import '../model/excluded_account.dart';
import '../usecase/load_excluded_accounts.dart';

class ExcludedAccountState {
  const ExcludedAccountState({
    this.accounts = const [],
    this.isLoading = true,
    this.restoringXUserId,
    this.errorMessage,
    this.noticeMessage,
  });

  final List<ExcludedAccount> accounts;
  final bool isLoading;
  final String? restoringXUserId;
  final String? errorMessage;
  final String? noticeMessage;
}

class ExcludedAccountVm extends ChangeNotifier {
  ExcludedAccountVm(this._loadExcludedAccounts, this._restoreCandidate) {
    _subscription = _loadExcludedAccounts().listen(
      (accounts) {
        _state = ExcludedAccountState(
          accounts: accounts,
          isLoading: false,
          noticeMessage: _state.noticeMessage,
        );
        notifyListeners();
      },
      onError: (_) {
        _state = const ExcludedAccountState(
          isLoading: false,
          errorMessage: '除外リストの読み込みに失敗しました。',
        );
        notifyListeners();
      },
    );
  }

  final LoadExcludedAccounts _loadExcludedAccounts;
  final RestoreCandidate _restoreCandidate;
  late final StreamSubscription<List<ExcludedAccount>> _subscription;

  ExcludedAccountState _state = const ExcludedAccountState();

  ExcludedAccountState get state => _state;

  Future<void> restore(ExcludedAccount account) async {
    _state = ExcludedAccountState(
      accounts: _state.accounts,
      isLoading: false,
      restoringXUserId: account.xUserId,
    );
    notifyListeners();

    try {
      await _restoreCandidate(account.candidateId);
      _state = ExcludedAccountState(
        accounts: _state.accounts,
        isLoading: false,
        noticeMessage: '${account.displayUserName}を除外リストから戻しました。',
      );
      notifyListeners();
    } on AppError catch (error) {
      _state = ExcludedAccountState(
        accounts: _state.accounts,
        isLoading: false,
        errorMessage: error.message,
      );
      notifyListeners();
    } catch (_) {
      _state = ExcludedAccountState(
        accounts: _state.accounts,
        isLoading: false,
        errorMessage: '除外解除に失敗しました。',
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
