import 'package:flutter/material.dart';

import '../../../../app/di/providers.dart';
import '../../../../core/ui/widgets/app_scaffold.dart';
import '../../model/conversion.dart';
import '../../vm/conversion_form_vm.dart';
import '../../vm/conversion_list_vm.dart';

class ConversionListPage extends StatelessWidget {
  const ConversionListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = AppProviders.of(context);
    return AppScaffold(
      title: '成約記録',
      body: _ConversionPageBody(
        listVm: ConversionListVm(dependencies.loadConversions),
        formVm: ConversionFormVm(
          dependencies.loadSendHistories,
          dependencies.createConversion,
        ),
      ),
    );
  }
}

class _ConversionPageBody extends StatefulWidget {
  const _ConversionPageBody({required this.listVm, required this.formVm});

  final ConversionListVm listVm;
  final ConversionFormVm formVm;

  @override
  State<_ConversionPageBody> createState() => _ConversionPageBodyState();
}

class _ConversionPageBodyState extends State<_ConversionPageBody> {
  @override
  void dispose() {
    widget.listVm.dispose();
    widget.formVm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConversionForm(vm: widget.formVm),
            const SizedBox(height: 32),
            _ConversionList(vm: widget.listVm),
          ],
        ),
      ),
    );
  }
}

class _ConversionForm extends StatelessWidget {
  const _ConversionForm({required this.vm});

  final ConversionFormVm vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final state = vm.state;
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '成約記録を登録',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: state.selectedHistoryId,
                  items: state.histories.map((history) {
                    return DropdownMenuItem(
                      value: history.historyId,
                      child: Text(
                        '${history.displayUserName} / ${history.sendMethodLabel} / ${_formatDateTime(history.sentAt)}',
                      ),
                    );
                  }).toList(),
                  onChanged: state.isSubmitting ? null : vm.selectHistory,
                  decoration: const InputDecoration(labelText: '送信履歴'),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: 220,
                      child: TextFormField(
                        initialValue: state.salesAmountText,
                        enabled: !state.isSubmitting,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '対象売上'),
                        onChanged: vm.changeSalesAmount,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: state.evidenceNote,
                  enabled: !state.isSubmitting,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: '補足メモ'),
                  onChanged: vm.changeEvidenceNote,
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (state.noticeMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(state.noticeMessage!),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: state.isSubmitting ? null : vm.submit,
                  child: Text(state.isSubmitting ? '登録中' : '成約記録を登録'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ConversionList extends StatelessWidget {
  const _ConversionList({required this.vm});

  final ConversionListVm vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final state = vm.state;
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.errorMessage != null) {
          return Center(child: Text(state.errorMessage!));
        }
        if (state.conversions.isEmpty) {
          return const Center(child: Text('成約記録はまだ登録されていません。'));
        }
        return _ConversionTable(conversions: state.conversions);
      },
    );
  }
}

class _ConversionTable extends StatelessWidget {
  const _ConversionTable({required this.conversions});

  final List<Conversion> conversions;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('候補者')),
          DataColumn(label: Text('Xユーザー名')),
          DataColumn(label: Text('対象売上')),
          DataColumn(label: Text('ステータス')),
          DataColumn(label: Text('登録日時')),
        ],
        rows: conversions.map((conversion) {
          return DataRow(
            cells: [
              DataCell(Text(conversion.displayUserName)),
              DataCell(Text(_username(conversion))),
              DataCell(Text(_formatMoney(conversion.salesAmount))),
              DataCell(Text(conversion.statusLabel)),
              DataCell(Text(_formatDateTime(conversion.createdAt))),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _username(Conversion conversion) {
    if (conversion.username.isEmpty) {
      return conversion.xUserId;
    }
    return '@${conversion.username}';
  }
}

String _formatMoney(num? value) {
  if (value == null) {
    return '-';
  }
  return value.round().toString();
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
