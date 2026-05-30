import 'package:flutter_test/flutter_test.dart';

import 'package:standup/main.dart';

void main() {
  testWidgets('StandUp app renders home shell', (WidgetTester tester) async {
    await tester.pumpWidget(const StandUpApp());
    await tester.pump();

    expect(find.text('今天动了吗？'), findsOneWidget);
  });
}
