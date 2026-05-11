import 'package:flutter/material.dart';

class QueueProgress extends StatelessWidget {
  const QueueProgress({
    required this.current,
    required this.total,
    super.key,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Text('$current / $total件目');
  }
}
