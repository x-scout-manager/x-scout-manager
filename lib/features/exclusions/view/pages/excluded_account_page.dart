import 'package:flutter/material.dart';

import '../../../../app/di/providers.dart';
import '../../../../core/ui/widgets/app_scaffold.dart';
import '../../model/excluded_account.dart';
import '../../vm/excluded_account_vm.dart';

class ExcludedAccountPage extends StatelessWidget {
  const ExcludedAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = AppProviders.of(context);
    return AppScaffold(
      title: '除外リスト',
      body: _ExcludedAccountBody(
        vm: ExcludedAccountVm(
          dependencies.loadExcludedAccounts,
          dependencies.restoreCandidate,
        ),
      ),
    );
  }
}

class _ExcludedAccountBody extends StatefulWidget {
  const _ExcludedAccountBody({required this.vm});

  final ExcludedAccountVm vm;

  @override
  State<_ExcludedAccountBody> createState() => _ExcludedAccountBodyState();
}

class _ExcludedAccountBodyState extends State<_ExcludedAccountBody> {
  @override
  void dispose() {
    widget.vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        final state = widget.vm.state;
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '除外中 ${state.accounts.length}件',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (state.noticeMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(state.noticeMessage!),
                ],
                const SizedBox(height: 24),
                if (state.accounts.isEmpty)
                  const Center(child: Text('除外中のアカウントはありません。'))
                else
                  _ExcludedAccountTable(
                    accounts: state.accounts,
                    restoringXUserId: state.restoringXUserId,
                    onRestore: widget.vm.restore,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ExcludedAccountTable extends StatelessWidget {
  const _ExcludedAccountTable({
    required this.accounts,
    required this.restoringXUserId,
    required this.onRestore,
  });

  final List<ExcludedAccount> accounts;
  final String? restoringXUserId;
  final Future<void> Function(ExcludedAccount account) onRestore;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('ユーザー名')),
          DataColumn(label: Text('表示名')),
          DataColumn(label: Text('理由')),
          DataColumn(label: Text('キーワード')),
          DataColumn(label: Text('更新日時')),
          DataColumn(label: Text('操作')),
        ],
        rows: accounts.map((account) {
          final isRestoring = restoringXUserId == account.xUserId;
          return DataRow(
            cells: [
              DataCell(Text(_username(account))),
              DataCell(Text(account.displayName ?? '-')),
              DataCell(Text(_blankToDash(account.reason))),
              DataCell(Text(_keywords(account))),
              DataCell(Text(_formatDateTime(account.updatedAt))),
              DataCell(
                TextButton(
                  onPressed: isRestoring ? null : () => onRestore(account),
                  child: Text(isRestoring ? '復帰中' : '除外解除'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _keywords(ExcludedAccount account) {
    if (account.matchedKeywords.isEmpty) {
      return '-';
    }
    return account.matchedKeywords.join(', ');
  }

  String _username(ExcludedAccount account) {
    if (account.username.isEmpty) {
      return account.xUserId;
    }
    return '@${account.username}';
  }
}

String _blankToDash(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '-';
  }
  return value;
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return '-';
  }
  final local = value.toLocal();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${local.year}/${twoDigits(local.month)}/${twoDigits(local.day)} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}
