import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myapp/main.dart';

void main() {
  testWidgets('Dashboard renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('داشبورد'), findsOneWidget);
    expect(find.byType(ActionChip), findsNWidgets(4));
  });
}
