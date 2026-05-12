import 'package:flutter/material.dart';

import '../../../../core/ui/components/primary_button.dart';
import '../../model/dm_template.dart';
import '../../vm/template_list_vm.dart';

class TemplateEditor extends StatefulWidget {
  const TemplateEditor({required this.vm, super.key});

  final TemplateListVm vm;

  @override
  State<TemplateEditor> createState() => _TemplateEditorState();
}

class _TemplateEditorState extends State<TemplateEditor> {
  late final TextEditingController _nameController;
  late final TextEditingController _bodyController;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bodyController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bodyController.dispose();
    widget.vm.dispose();
    super.dispose();
  }

  void _syncEditing(DmTemplate template) {
    if (_editingId == template.templateId &&
        _nameController.text == template.name &&
        _bodyController.text == template.body) {
      return;
    }
    _editingId = template.templateId;
    _nameController.text = template.name;
    _bodyController.text = template.body;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        final state = widget.vm.state;
        _syncEditing(state.editing);

        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TemplateForm(
                  nameController: _nameController,
                  bodyController: _bodyController,
                  state: state,
                  onNameChanged: widget.vm.updateName,
                  onBodyChanged: widget.vm.updateBody,
                  onActiveChanged: widget.vm.updateIsActive,
                  onCreateNew: widget.vm.startCreate,
                  onSave: widget.vm.saveEditing,
                ),
                const SizedBox(height: 32),
                _TemplateList(
                  templates: state.templates,
                  isSaving: state.isSaving,
                  onEdit: widget.vm.startEdit,
                  onDisable: widget.vm.disable,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TemplateForm extends StatelessWidget {
  const _TemplateForm({
    required this.nameController,
    required this.bodyController,
    required this.state,
    required this.onNameChanged,
    required this.onBodyChanged,
    required this.onActiveChanged,
    required this.onCreateNew,
    required this.onSave,
  });

  final TextEditingController nameController;
  final TextEditingController bodyController;
  final TemplateListState state;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onBodyChanged;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onCreateNew;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final editing = state.editing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          editing.templateId.isEmpty ? '新規テンプレート' : 'テンプレート編集',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'テンプレート名'),
          onChanged: onNameChanged,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: bodyController,
          decoration: const InputDecoration(labelText: '本文'),
          minLines: 6,
          maxLines: 10,
          onChanged: onBodyChanged,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('有効'),
          value: editing.isActive,
          onChanged: state.isSaving ? null : onActiveChanged,
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            state.errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (state.noticeMessage != null) ...[
          const SizedBox(height: 16),
          Text(state.noticeMessage!),
        ],
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            PrimaryButton(
              label: state.isSaving ? '保存中' : '保存',
              onPressed: state.isSaving ? null : onSave,
            ),
            OutlinedButton(
              onPressed: state.isSaving ? null : onCreateNew,
              child: const Text('新規作成'),
            ),
          ],
        ),
      ],
    );
  }
}

class _TemplateList extends StatelessWidget {
  const _TemplateList({
    required this.templates,
    required this.isSaving,
    required this.onEdit,
    required this.onDisable,
  });

  final List<DmTemplate> templates;
  final bool isSaving;
  final ValueChanged<DmTemplate> onEdit;
  final ValueChanged<DmTemplate> onDisable;

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
      return const Text('テンプレートは未登録です。');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('登録済みテンプレート', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...templates.map((template) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(template.name),
              subtitle: Text(
                template.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              leading: Icon(
                template.isActive ? Icons.check_circle : Icons.pause_circle,
                color: template.isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
              ),
              trailing: Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: isSaving ? null : () => onEdit(template),
                    child: const Text('編集'),
                  ),
                  TextButton(
                    onPressed: isSaving || !template.isActive
                        ? null
                        : () => onDisable(template),
                    child: const Text('無効化'),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
