import 'package:flutter/material.dart';

import '../../../../app/di/providers.dart';
import '../../../../core/ui/components/primary_button.dart';
import '../../../../core/ui/widgets/app_scaffold.dart';
import '../../vm/exclusion_keyword_vm.dart';

class ExclusionKeywordSettingPage extends StatelessWidget {
  const ExclusionKeywordSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = AppProviders.of(context);
    return AppScaffold(
      title: '除外キーワード設定',
      body: _ExclusionKeywordBody(
        vm: ExclusionKeywordVm(
          dependencies.exclusionRepository,
          dependencies.saveExclusionKeywords,
        ),
      ),
    );
  }
}

class _ExclusionKeywordBody extends StatefulWidget {
  const _ExclusionKeywordBody({required this.vm});

  final ExclusionKeywordVm vm;

  @override
  State<_ExclusionKeywordBody> createState() => _ExclusionKeywordBodyState();
}

class _ExclusionKeywordBodyState extends State<_ExclusionKeywordBody> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.vm.dispose();
    super.dispose();
  }

  void _addKeyword() {
    widget.vm.addKeyword(_controller.text);
    if (widget.vm.state.errorMessage == null) {
      _controller.clear();
    }
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
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(labelText: '除外キーワード'),
                        onSubmitted: (_) => _addKeyword(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: state.isSaving ? null : _addKeyword,
                      child: const Text('追加'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.keywords.map((keyword) {
                    return InputChip(
                      label: Text(keyword.keyword),
                      onDeleted: state.isSaving
                          ? null
                          : () => widget.vm.removeKeyword(keyword.keyword),
                    );
                  }).toList(),
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
