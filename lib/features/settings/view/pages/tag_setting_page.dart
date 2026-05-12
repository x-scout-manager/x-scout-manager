import 'package:flutter/material.dart';

import '../../../../app/di/providers.dart';
import '../../../../core/ui/components/primary_button.dart';
import '../../../../core/ui/widgets/app_scaffold.dart';
import '../../vm/tag_setting_vm.dart';

class TagSettingPage extends StatelessWidget {
  const TagSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = AppProviders.of(context);
    return AppScaffold(
      title: 'タグ設定',
      body: _TagSettingBody(
        vm: TagSettingVm(dependencies.loadScoutSettings, dependencies.saveTags),
      ),
    );
  }
}

class _TagSettingBody extends StatefulWidget {
  const _TagSettingBody({required this.vm});

  final TagSettingVm vm;

  @override
  State<_TagSettingBody> createState() => _TagSettingBodyState();
}

class _TagSettingBodyState extends State<_TagSettingBody> {
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

  void _addTag() {
    widget.vm.addTag(_controller.text);
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
                        decoration: const InputDecoration(labelText: 'タグ'),
                        onSubmitted: (_) => _addTag(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: state.isSaving ? null : _addTag,
                      child: const Text('追加'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.tags.map((tag) {
                    return InputChip(
                      label: Text('#${tag.tag}'),
                      onDeleted: state.isSaving
                          ? null
                          : () => widget.vm.removeTag(tag.tag),
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
