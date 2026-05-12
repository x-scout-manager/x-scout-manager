import 'package:flutter/material.dart';

import '../../../../app/di/providers.dart';
import '../../../../core/ui/widgets/app_scaffold.dart';
import '../../vm/candidate_list_vm.dart';
import '../widgets/candidate_table.dart';

class CandidateListPage extends StatelessWidget {
  const CandidateListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = AppProviders.of(context);
    return AppScaffold(
      title: '候補一覧',
      body: _CandidateListBody(
        vm: CandidateListVm(dependencies.loadCandidates),
      ),
    );
  }
}

class _CandidateListBody extends StatefulWidget {
  const _CandidateListBody({required this.vm});

  final CandidateListVm vm;

  @override
  State<_CandidateListBody> createState() => _CandidateListBodyState();
}

class _CandidateListBodyState extends State<_CandidateListBody> {
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
        if (state.errorMessage != null) {
          return Center(child: Text(state.errorMessage!));
        }
        return Padding(
          padding: const EdgeInsets.all(24),
          child: CandidateTable(candidates: state.candidates),
        );
      },
    );
  }
}
