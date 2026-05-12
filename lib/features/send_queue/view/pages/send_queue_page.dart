import 'package:flutter/material.dart';

import '../../../../core/ui/widgets/app_scaffold.dart';
import '../widgets/message_preview.dart';
import '../widgets/queue_progress.dart';

class SendQueuePage extends StatelessWidget {
  const SendQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final queueId = ModalRoute.of(context)?.settings.arguments;
    return AppScaffold(
      title: '送信キュー',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (queueId is String && queueId.isNotEmpty) ...[
              Text('キューID: $queueId'),
              const SizedBox(height: 16),
            ],
            const QueueProgress(current: 0, total: 0),
            const SizedBox(height: 24),
            const MessagePreview(message: 'DM本文は未選択です'),
          ],
        ),
      ),
    );
  }
}
