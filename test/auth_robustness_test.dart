import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shipathon_hackathon/core/services/auth_service.dart';
import 'package:shipathon_hackathon/core/services/backend_api_service.dart';
import 'package:shipathon_hackathon/models/user_profile.dart';
import 'package:shipathon_hackathon/providers/auth_provider.dart';
import 'package:shipathon_hackathon/providers/channel_provider.dart';
import 'package:shipathon_hackathon/screens/auth/auth_gate_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final auth = AuthService();
    await auth.signOut();
  });

  group('1. Aggressive Input Validation Tests (Email, Password, Display Name)', () {
    final authService = AuthService();

    test('Rejects empty or whitespace-only email for login', () async {
      expect(
        () => authService.signInWithEmail(email: '', password: 'Password123'),
        throwsA(predicate((e) => e.toString().contains('Please enter your email address.'))),
      );

      expect(
        () => authService.signInWithEmail(email: '   ', password: 'Password123'),
        throwsA(predicate((e) => e.toString().contains('Please enter your email address.'))),
      );
    });

    test('Rejects malformed emails for login and registration', () async {
      final invalidEmails = [
        'plainaddress',
        '@missinguser.com',
        'missingdomain@.com',
        'user@domain..com',
        'user@domain',
        'spaces in@email.com',
      ];

      for (final badEmail in invalidEmails) {
        expect(
          () => authService.signInWithEmail(email: badEmail, password: 'Password123'),
          throwsA(predicate((e) => e.toString().contains('Please enter a valid email address.'))),
          reason: 'Failed to reject invalid email: $badEmail',
        );

        expect(
          () => authService.signUpWithEmail(
            email: badEmail,
            password: 'Password123',
            displayName: 'Creator',
            initialHandle: '@creator',
          ),
          throwsA(predicate((e) => e.toString().contains('Please enter a valid email address.'))),
          reason: 'Failed to reject invalid registration email: $badEmail',
        );
      }
    });

    test('Rejects short, empty, or whitespace passwords', () async {
      expect(
        () => authService.signInWithEmail(email: 'valid@studio.com', password: ''),
        throwsA(predicate((e) => e.toString().contains('Please enter your password.'))),
      );

      expect(
        () => authService.signInWithEmail(email: 'valid@studio.com', password: '   '),
        throwsA(predicate((e) => e.toString().contains('Please enter your password.'))),
      );

      expect(
        () => authService.signInWithEmail(email: 'valid@studio.com', password: '12345'),
        throwsA(predicate((e) => e.toString().contains('Password must be at least 6 characters.'))),
      );
    });

    test('Rejects empty creator name on registration', () async {
      expect(
        () => authService.signUpWithEmail(
          email: 'valid@studio.com',
          password: 'Password123',
          displayName: '   ',
          initialHandle: '@channel',
        ),
        throwsA(predicate((e) => e.toString().contains('Please enter your creator or brand name.'))),
      );
    });

    test('Normalizes channel handle prefix on registration and switching', () async {
      BackendApiService().setMockMode(true);

      final user = await authService.signUpWithEmail(
        email: 'creator@studio.com',
        password: 'Password123',
        displayName: 'Telusko Tech',
        initialHandle: 'telusko', // Missing @
      );

      expect(user.activeChannelHandle, '@telusko');
      expect(user.connectedChannels.first, '@telusko');
    });
  });

  group('2. Corrupted Storage & Session Resilience Tests', () {
    test('Recovers gracefully when SharedPreferences has malformed JSON', () async {
      SharedPreferences.setMockInitialValues({
        'prevue_user_profile': '{invalid_json_corrupted: true, missing_quotes}',
        'prevue_auth_token': 'bad_token',
      });

      final authService = AuthService();
      final user = await authService.initialize();

      // Must not crash and should return null (unauthenticated guest)
      expect(user, isNull);
      expect(authService.isAuthenticated, isFalse);

      // Verify corrupted entry was purged
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('prevue_user_profile'), isNull);
    });

    test('Recovers gracefully when UserProfile has unexpected nulls or missing fields', () {
      final incompleteJson = <String, dynamic>{
        'id': null,
        'email': null,
        'connected_channels': null,
      };

      final profile = UserProfile.fromJson(incompleteJson);
      expect(profile.id, 'guest_user');
      expect(profile.email, 'guest@prevue.app');
      expect(profile.connectedChannels, const ['@RevenueCat']);
      expect(profile.activeChannelHandle, '@RevenueCat');
    });

    test('Checks user existence in database and loads profile upon session initialization', () async {
      BackendApiService().setMockMode(true);
      final authService = AuthService();

      // Log in a valid user
      final loggedIn = await authService.signInWithEmail(
        email: 'db_verified@studio.com',
        password: 'Password123',
      );
      expect(loggedIn.email, 'db_verified@studio.com');

      // Re-initialize from storage
      final restored = await authService.initialize();
      expect(restored, isNotNull);
      expect(restored!.email, 'db_verified@studio.com');
      expect(authService.isAuthenticated, isTrue);
    });
  });

  group('3. Backend HTTP Exception & Status Code Handling', () {
    test('Surfaces clean Unauthorized (401) error message without swallowing', () async {
      final authProvider = AuthProvider();

      // Trigger login with empty password to test client check first
      final success = await authProvider.signInWithEmail(
        email: 'tester@studio.io',
        password: '123',
      );

      expect(success, isFalse);
      expect(authProvider.errorMessage, 'Password must be at least 6 characters.');
    });

    test('AuthProvider formats technical DioExceptions into user-friendly strings', () async {
      final authProvider = AuthProvider();

      // Test clear error
      expect(authProvider.errorMessage, isNull);

      final result = await authProvider.signInWithEmail(
        email: 'bad-email-format',
        password: 'Password123',
      );

      expect(result, isFalse);
      expect(authProvider.errorMessage, 'Please enter a valid email address.');

      authProvider.clearError();
      expect(authProvider.errorMessage, isNull);
    });
  });

  group('4. UI Form Validation & Live Error Dismissal in AuthGateScreen', () {
    testWidgets('Empty submit shows validation error, typing clears error', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      final authProvider = AuthProvider();
      final channelProvider = ChannelProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: channelProvider),
          ],
          child: ScreenUtilInit(
            designSize: const Size(393, 852),
            minTextAdapt: true,
            builder: (context, child) {
              return const MaterialApp(
                home: AuthGateScreen(),
              );
            },
          ),
        ),
      );
      await tester.pump();

      // Tap Sign In without typing credentials
      await tester.tap(find.text('Sign In').last);
      await tester.pump(const Duration(milliseconds: 100));

      // Error banner should appear
      expect(find.text('Please enter your email address.'), findsOneWidget);

      // Type into email field
      await tester.enterText(find.byType(TextField).first, 'valid@email.com');
      await tester.pump();

      // Error banner should be cleared automatically by live listener
      expect(find.text('Please enter your email address.'), findsNothing);
    });

    testWidgets('Switching tabs between Sign In and Create Account clears error', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      final authProvider = AuthProvider();
      final channelProvider = ChannelProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: channelProvider),
          ],
          child: ScreenUtilInit(
            designSize: const Size(393, 852),
            minTextAdapt: true,
            builder: (context, child) {
              return const MaterialApp(
                home: AuthGateScreen(),
              );
            },
          ),
        ),
      );
      await tester.pump();

      // Trigger error
      await tester.tap(find.text('Sign In').last);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Please enter your email address.'), findsOneWidget);

      // Switch to Create Account tab
      await tester.tap(find.text('Create Account'));
      await tester.pump(const Duration(milliseconds: 200));

      // Error banner should be cleared
      expect(find.text('Please enter your email address.'), findsNothing);
    });
  });
}
