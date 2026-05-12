import 'package:flutter/material.dart';

import '../../../../core/ui/components/primary_button.dart';
import '../../vm/system_setting_vm.dart';

class SystemSettingBody extends StatefulWidget {
  const SystemSettingBody({required this.vm, super.key});

  final SystemSettingVm vm;

  @override
  State<SystemSettingBody> createState() => _SystemSettingBodyState();
}

class _SystemSettingBodyState extends State<SystemSettingBody> {
  late final TextEditingController _searchMaxResultsController;
  late final TextEditingController _searchMaxPagesController;
  late final TextEditingController _recentSearchDaysController;
  late final TextEditingController _defaultRewardRateController;
  bool _synced = false;

  @override
  void initState() {
    super.initState();
    _searchMaxResultsController = TextEditingController();
    _searchMaxPagesController = TextEditingController();
    _recentSearchDaysController = TextEditingController();
    _defaultRewardRateController = TextEditingController();
  }

  @override
  void dispose() {
    _searchMaxResultsController.dispose();
    _searchMaxPagesController.dispose();
    _recentSearchDaysController.dispose();
    _defaultRewardRateController.dispose();
    widget.vm.dispose();
    super.dispose();
  }

  void _syncControllers(SystemSettingState state) {
    if (_synced || state.isLoading) {
      return;
    }
    final settings = state.settings;
    _searchMaxResultsController.text = settings.searchMaxResults.toString();
    _searchMaxPagesController.text = settings.searchMaxPages.toString();
    _recentSearchDaysController.text = settings.recentSearchDays.toString();
    _defaultRewardRateController.text = settings.defaultRewardRate.toString();
    _synced = true;
  }

  int? _intValue(String value) => int.tryParse(value.trim());

  num? _numValue(String value) => num.tryParse(value.trim());

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        final state = widget.vm.state;
        _syncControllers(state);

        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final settings = state.settings;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchMaxResultsController,
                  decoration: const InputDecoration(labelText: '検索取得件数'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final parsed = _intValue(value);
                    if (parsed != null) {
                      widget.vm.update(searchMaxResults: parsed);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchMaxPagesController,
                  decoration: const InputDecoration(labelText: '最大ページ数'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final parsed = _intValue(value);
                    if (parsed != null) {
                      widget.vm.update(searchMaxPages: parsed);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _recentSearchDaysController,
                  decoration: const InputDecoration(labelText: '検索対象日数'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final parsed = _intValue(value);
                    if (parsed != null) {
                      widget.vm.update(recentSearchDays: parsed);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _defaultRewardRateController,
                  decoration: const InputDecoration(labelText: '標準成果報酬率'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) {
                    final parsed = _numValue(value);
                    if (parsed != null) {
                      widget.vm.update(defaultRewardRate: parsed);
                    }
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('X API DM送信'),
                  value: settings.apiDmEnabled,
                  onChanged: state.isSaving
                      ? null
                      : (value) => widget.vm.update(apiDmEnabled: value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('手動送信支援'),
                  value: settings.manualSendEnabled,
                  onChanged: state.isSaving
                      ? null
                      : (value) => widget.vm.update(manualSendEnabled: value),
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
                PrimaryButton(
                  label: state.isSaving ? '保存中' : '保存',
                  onPressed: state.isSaving ? null : widget.vm.save,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
