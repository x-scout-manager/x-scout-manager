import 'package:flutter/material.dart';

import '../../../../core/ui/widgets/app_scaffold.dart';
import '../widgets/message_preview.dart';
import '../widgets/queue_progress.dart';

class SendQueuePage extends StatelessWidget {
  const SendQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: '送信キュー',
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QueueProgress(current: 0, total: 0),
            SizedBox(height: 24),
            MessagePreview(message: 'DM本文は未選択です'),
          ],
        ),
      ),
    );
  }
}
