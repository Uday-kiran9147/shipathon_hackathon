import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shipathon_hackathon/core/theme/app_colors.dart';
import 'package:shipathon_hackathon/widgets/common/coming_soon_card.dart';

Widget _buildTestWrapper({
  required Widget child,
  Size screenSize = const Size(390, 844),
  double textScaleFactor = 1.0,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: screenSize,
      textScaler: TextScaler.linear(textScaleFactor),
    ),
    child: ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.canvas,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ComingSoonCard Tests', () {
    testWidgets('renders simple ComingSoonCard with animated text, title, and description', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestWrapper(
          child: const ComingSoonCard(
            title: 'Creator Pro',
            description: 'Exciting new intelligence features are on the way. Stay tuned for our next major release!',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('COMING SOON'), findsOneWidget);
      expect(find.text('Creator Pro'), findsOneWidget);
      expect(
        find.text('Exciting new intelligence features are on the way. Stay tuned for our next major release!'),
        findsOneWidget,
      );
    });

    testWidgets('renders custom title and description', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestWrapper(
          child: const ComingSoonCard(
            title: 'Neural Script Co-Pilot',
            description: 'Generate multi-hook scripts tailored to your channel persona.',
            icon: Icons.psychology_rounded,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('COMING SOON'), findsOneWidget);
      expect(find.text('Neural Script Co-Pilot'), findsOneWidget);
      expect(
        find.text('Generate multi-hook scripts tailored to your channel persona.'),
        findsOneWidget,
      );
    });

    testWidgets('Responsive & Adaptive layout test across compact and tablet screens without overflow', (
      WidgetTester tester,
    ) async {
      final viewports = [
        const Size(320, 568), // Compact iPhone SE
        const Size(360, 800), // Standard Android
        const Size(390, 844), // Modern iPhone
        const Size(412, 915), // Large Android
        const Size(768, 1024), // Tablet
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _buildTestWrapper(
            screenSize: size,
            textScaleFactor: 1.5, // High text scale factor
            child: const ComingSoonCard(
              title: 'Audience Demand Graph & Semantic Cross-Platform Mining',
              description:
                  'Deep-learning audience comment graph engine to predict retention drops before filming.',
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        // Expect zero RenderFlex overflow errors
        expect(tester.takeException(), isNull);
        expect(find.text('COMING SOON'), findsOneWidget);
      }
    });

    testWidgets('ComingSoonCard.show presents clean modal with Coming Soon card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestWrapper(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ComingSoonCard.show(context),
              child: const Text('Go Pro'),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap Go Pro
      await tester.tap(find.text('Go Pro'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Coming Soon modal is presented
      expect(find.text('COMING SOON'), findsOneWidget);
      expect(find.text('Creator Pro'), findsOneWidget);
    });
  });
}
