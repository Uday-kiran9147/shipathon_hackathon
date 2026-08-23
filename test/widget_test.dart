import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shipathon_hackathon/main.dart';

void main() {
  testWidgets('TubeSimul8App smoke test', (WidgetTester tester) async {
    // Set standard mobile device viewport for ScreenUtil (390 x 844)
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const TubeSimul8App());
    await tester.pump(const Duration(seconds: 1));

    // Verify that the Daily Briefing screen loads
    expect(find.text('Daily Briefing'), findsOneWidget);
    expect(find.text('All Blueprints'), findsOneWidget);
  });
}
