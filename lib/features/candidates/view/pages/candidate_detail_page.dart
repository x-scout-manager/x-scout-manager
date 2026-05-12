import 'package:flutter/material.dart';

import '../../../../app/di/providers.dart';
import '../../../../core/ui/widgets/app_scaffold.dart';
import '../../model/candidate.dart';
import '../../vm/candidate_detail_vm.dart';
import '../widgets/candidate_status_badge.dart';

class CandidateDetailPage extends StatelessWidget {
  const CandidateDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final candidateId = ModalRoute.of(context)?.settings.arguments;
    if (candidateId is! String || candidateId.isEmpty) {
      return const AppScaffold(
        title: '候補詳細',
        body: Center(child: Text('候補IDが指定されていません。')),
      );
    }

    final dependencies = AppProviders.of(context);
    return AppScaffold(
      title: '候補詳細',
      body: _CandidateDetailBody(
        vm: CandidateDetailVm(dependencies.candidateRepository, candidateId),
      ),
    );
  }
}

class _CandidateDetailBody extends StatefulWidget {
  const _CandidateDetailBody({required this.vm});

  final CandidateDetailVm vm;

  @override
  State<_CandidateDetailBody> createState() => _CandidateDetailBodyState();
}

class _CandidateDetailBodyState extends State<_CandidateDetailBody> {
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
        final candidate = state.candidate;
        if (candidate == null) {
          return const Center(child: Text('候補が見つかりません。'));
        }
        return _CandidateDetail(candidate: candidate);
      },
    );
  }
}

class _CandidateDetail extends StatelessWidget {
  const _CandidateDetail({required this.candidate});

  final Candidate candidate;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              candidate.displayName ?? '@${candidate.username}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('@${candidate.username}'),
            const SizedBox(height: 16),
            CandidateStatusBadge(status: candidate.status),
            const SizedBox(height: 24),
            _DetailRow(label: '候補ID', value: candidate.candidateId),
            _DetailRow(label: 'XユーザーID', value: candidate.xUserId),
            _DetailRow(label: 'プロフィールURL', value: candidate.profileUrl ?? '-'),
            _DetailRow(
              label: '抽出元タグ',
              value: candidate.sourceTags.isEmpty
                  ? '-'
                  : candidate.sourceTags.join(', '),
            ),
            _DetailRow(label: '送信可否', value: candidate.canSend ? '可' : '不可'),
            _DetailRow(
              label: '除外対象',
              value: candidate.isExcluded ? 'はい' : 'いいえ',
            ),
            _DetailRow(label: '送信済み', value: candidate.isSent ? 'はい' : 'いいえ'),
            const SizedBox(height: 24),
            Text('プロフィール', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(candidate.profileText ?? '-'),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
