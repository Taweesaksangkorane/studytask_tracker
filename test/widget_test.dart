import 'package:flutter_test/flutter_test.dart';

import 'package:studytask_tracker/main.dart';

void main() {
  testWidgets('shows the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('StudyTask'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
