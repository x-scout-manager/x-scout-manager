import 'package:flutter_test/flutter_test.dart';
import 'package:x_scout_manager/app/app.dart';

void main() {
  testWidgets('shows dashboard as initial page', (tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('ダッシュボード'), findsOneWidget);
    expect(find.text('候補'), findsOneWidget);
    expect(find.text('送信済み'), findsOneWidget);
    expect(find.text('除外'), findsOneWidget);
  });
}
