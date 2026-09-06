import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shipathon_hackathon/main.dart';

import 'package:shipathon_hackathon/models/channel_graph.dart';
import 'package:shipathon_hackathon/models/daily_blueprint.dart';
import 'package:shipathon_hackathon/models/simulation_result.dart';
import 'package:shipathon_hackathon/core/services/auth_service.dart';
import 'package:shipathon_hackathon/core/services/backend_api_service.dart';
import 'package:shipathon_hackathon/models/user_profile.dart';
import 'package:shipathon_hackathon/providers/auth_provider.dart';

final _transparentImage = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x42,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

class _MockHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _transparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_transparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Future<Socket> detachSocket() => throw UnimplementedError();
  @override
  List<RedirectInfo> get redirects => [];
  @override
  bool get isRedirect => false;
  @override
  bool get persistentConnection => true;
  @override
  String get reasonPhrase => 'OK';
  @override
  X509Certificate? get certificate => null;
  @override
  HttpConnectionInfo? get connectionInfo => null;
  @override
  List<Cookie> get cookies => [];
  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) => throw UnimplementedError();
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  List<String>? operator [](String name) => null;
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void clear() {}
  @override
  void noFolding(String name) {}
  @override
  void remove(String name, Object value) {}
  @override
  void removeAll(String name) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  String? value(String name) => null;
  @override
  bool chunkedTransferEncoding = false;
  @override
  int contentLength = -1;
  @override
  ContentType? contentType;
  @override
  DateTime? date;
  @override
  DateTime? expires;
  @override
  String? host;
  @override
  DateTime? ifModifiedSince;
  @override
  bool persistentConnection = true;
  @override
  int? port;
  @override
  void forEach(void Function(String name, List<String> values) action) {}
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  bool bufferOutput = true;
  @override
  int contentLength = -1;
  @override
  Encoding encoding = utf8;
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  String method = 'GET';
  @override
  Uri get uri => Uri.parse('http://localhost');
  @override
  void add(List<int> data) {}
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future addStream(Stream<List<int>> stream) async {}
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
  @override
  HttpConnectionInfo? get connectionInfo => null;
  @override
  List<Cookie> get cookies => [];
  @override
  Future<HttpClientResponse> get done async => _MockHttpClientResponse();
  @override
  void write(Object? obj) {}
  @override
  void writeAll(Iterable objects, [String separator = '']) {}
  @override
  void writeCharCode(int charCode) {}
  @override
  void writeln([Object? obj = '']) {}
  @override
  bool persistentConnection = true;
  @override
  Future flush() async {}
  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;
  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) {}
  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) {}
  @override
  set authenticate(
    Future<bool> Function(Uri url, String scheme, String? realm)? f,
  ) {}
  @override
  set authenticateProxy(
    Future<bool> Function(String host, int port, String scheme, String? realm)?
    f,
  ) {}
  @override
  set badCertificateCallback(
    bool Function(X509Certificate cert, String host, int port)? callback,
  ) {}
  @override
  set findProxy(String Function(Uri url)? f) {}
  @override
  void close({bool force = false}) {}
  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      open('delete', host, port, path);
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('delete', url);
  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      open('get', host, port, path);
  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('get', url);
  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      open('head', host, port, path);
  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl('head', url);
  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) => openUrl(method, Uri(scheme: 'http', host: host, port: port, path: path));
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      open('patch', host, port, path);
  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl('patch', url);
  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      open('post', host, port, path);
  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('post', url);
  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      open('put', host, port, path);
  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('put', url);
  @override
  set connectionFactory(
    Future<ConnectionTask<Socket>> Function(
      Uri url,
      String? proxyHost,
      int? proxyPort,
    )?
    f,
  ) {}
  @override
  set keyLog(Function(String line)? callback) {}
}

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    HttpOverrides.global = MockHttpOverrides();
  });

  testWidgets('PrevueAPP mandatory auth gate & full studio navigation flow', (
    WidgetTester tester,
  ) async {
    // Set standard mobile device viewport for ScreenUtil (390 x 844)
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const PrevueAPP());
    await tester.pump(const Duration(seconds: 1));

    // Verify that AuthGateScreen is displayed initially (Mandatory Auth)
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('OR EMAIL LOGIN'), findsOneWidget);

    // Test switching to Create Account tab
    await tester.tap(find.text('Create Account'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('OR EMAIL SIGN UP'), findsOneWidget);

    // Switch back to Sign In tab
    await tester.tap(find.text('Sign In'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('OR EMAIL LOGIN'), findsOneWidget);

    // Authenticate via 1-Tap Google Sign-In
    await tester.tap(find.text('Continue with Google'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 1));

    // Verify that the studio unlocks into Daily Briefing screen
    expect(find.text('Daily Briefing'), findsOneWidget);
    expect(find.text('All Blueprints'), findsOneWidget);

    // Test tab navigation to Simulator Tab
    await tester.tap(find.text('Simulator').first);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Test Retention'), findsWidgets);

    // Test tab navigation to Channel Graph Tab
    await tester.tap(find.text('Channel').first);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('My Channel'), findsWidgets);
  });

  group('Comment Demand Clustering & Conviction Engine Tests', () {
    test('CommentDemandCluster model serialization and calculations', () {
      const cluster = CommentDemandCluster(
        id: 'cluster_test_01',
        topicKeyword: 'Spring Boot 3.3 GraalVM',
        sampleComments: [
          ChannelComment(
            id: 'c1',
            authorDisplayName: '@dev_lead',
            text:
                'Can you show how GraalVM native image works with Spring Boot 3.3 in production?',
            likeCount: 42,
            publishedAt: null,
            intentCategory: ChannelCommentIntent.request,
          ),
        ],
        totalUpvotes: 210,
        commentFrequency: 14,
        demandVelocityIndex: 8.5,
        primaryIntent: ChannelCommentIntent.request,
      );

      final json = cluster.toJson();
      final fromJson = CommentDemandCluster.fromJson(json);

      expect(fromJson.id, cluster.id);
      expect(fromJson.topicKeyword, cluster.topicKeyword);
      expect(fromJson.demandVelocityIndex, cluster.demandVelocityIndex);
      expect(fromJson.primaryIntent, ChannelCommentIntent.request);
      expect(fromJson.sampleComments.length, 1);
    });

    test('CreatorAuthenticityProfile model serialization', () {
      const profile = CreatorAuthenticityProfile(
        questionToPraiseRatio: 1.8,
        engagementVelocity: 34.2,
        signatureHookStyle: 'Direct question to terminal within 5 seconds',
        outlierVideoFormats: ['Crash Course', 'Code Teardown'],
        retentionVulnerabilityArea: '0:15 - 0:30 (Dependency setup)',
      );

      final json = profile.toJson();
      final fromJson = CreatorAuthenticityProfile.fromJson(json);

      expect(fromJson.questionToPraiseRatio, 1.8);
      expect(fromJson.engagementVelocity, 34.2);
      expect(fromJson.signatureHookStyle, contains('terminal'));
      expect(fromJson.outlierVideoFormats.contains('Crash Course'), isTrue);
    });

    test('ChannelGraph model serialization and performance ladder calculations', () {
      const graph = ChannelGraph(
        handle: '@RevenueCat',
        channelName: 'RevenueCat',
        medianViews: 5600,
        subscribers: 25000,
        uploadFrequency: 2.3,
        topOutlierMultiplier: 4.2,
      );

      expect(graph.medianViews, 5600);
      expect(graph.predictedPerformanceLadder['0.7x'], (5600 * 0.7).round());
      expect(graph.predictedPerformanceLadder['1.0x'], 5600);
      expect(graph.predictedPerformanceLadder['1.5x'], (5600 * 1.5).round());
      expect(graph.predictedPerformanceLadder['2.0x'], (5600 * 2.0).round());
      expect(graph.uploadFrequencyFormatted, '2.3 / week');
      expect(graph.isConfigured, isTrue);

      final json = graph.toJson();
      final fromJson = ChannelGraph.fromJson(json);
      expect(fromJson.handle, '@RevenueCat');
      expect(fromJson.medianViews, 5600);
    });
  });

  group('Simulator & Retention Models Tests', () {
    test('RetentionHazard model serialization and timestamp calculation', () {
      const hazard = RetentionHazard(
        startSeconds: 15,
        endSeconds: 30,
        severity: HazardSeverity.critical,
        dropOffRiskPercentage: 35,
        title: 'Explanatory lull detected',
        explanation: 'Viewer already knows background context.',
        flaggedScriptLine: 'In today video I will explain why this happens...',
      );

      expect(hazard.timestampRange, '0:15 - 0:30');
      expect(hazard.severity, HazardSeverity.critical);
      expect(hazard.dropOffRiskPercentage, 35);
    });

    test('SimulationResult model calculations and performance tiers', () {
      final now = DateTime.now();
      final result = SimulationResult(
        id: 'sim_1',
        title: 'Crash Course in Flutter Architecture',
        draftScript: 'Hello world...',
        format: BlueprintFormat.longForm,
        hookScore: 9.1,
        resonanceScore: 8.8,
        noveltyScore: 9.3,
        topicMomentumScore: 8.9,
        pacingScore: 9.0,
        creatorFitScore: 9.2,
        performanceTier: PerformanceTier.topOutlier,
        projectedViews: 18500,
        hazards: const [],
        fixes: const [
          PrescriptiveFix(
            id: 'fix_1',
            fixType: 'Hook Restructure',
            problem: 'Cut First 10 Seconds',
            description: 'Jump straight into the demonstration.',
            originalSnippet: 'Hello guys today I will talk about...',
            replacementSnippet: 'Here is the exact bug that caused the crash.',
            scoreLift: 1.2,
          ),
        ],
        createdAt: now,
      );

      expect(result.hookScore, 9.1);
      expect(result.performanceTier.title, 'Top 10% Channel Outlier');
      expect(result.projectedViews, 18500);
      expect(result.fixes.length, 1);
      expect(result.fixes.first.scoreLift, 1.2);
    });
  });

  group('Daily Blueprint Serialization & Resilient Parsing Tests', () {
    test('DailyBlueprint JSON serialization and format recognition', () {
      final now = DateTime.now();
      final bp = DailyBlueprint(
        id: 'bp_1',
        title: 'Mastering RevenueCat Paywalls in Flutter',
        format: BlueprintFormat.longForm,
        formatLabel: 'Long-Form (8–15m)',
        hookText: 'Most subscription apps fail because their paywall is shown at the wrong screen...',
        thumbnailConceptLeft: 'Broken Paywall Screen',
        thumbnailConceptRight: 'Optimized Revenue Chart',
        thumbnailTag: '3X CONVERSIONS',
        dataProofReason: 'Validated by top mobile dev audience demand.',
        predictedMultiplier: 2.8,
        convictionScore: 9.2,
        categoryTag: 'Mobile Monetization',
        date: now,
      );

      final json = bp.toJson();
      final fromJson = DailyBlueprint.fromJson(json);

      expect(fromJson.id, 'bp_1');
      expect(fromJson.title, 'Mastering RevenueCat Paywalls in Flutter');
      expect(fromJson.format, BlueprintFormat.longForm);
      expect(fromJson.predictedMultiplier, 2.8);
      expect(fromJson.convictionScore, 9.2);
      expect(fromJson.preEngineeredRetentionAnchors.isNotEmpty, isTrue);
    });
  });

  group('Authentication & Multi-Channel Workspace Tests', () {
    test('UserProfile model serialization and guest factory', () {
      final guest = UserProfile.guest('@Telusko');
      expect(guest.isGuest, isTrue);
      expect(guest.activeChannelHandle, '@Telusko');
      expect(guest.connectedChannels, contains('@Telusko'));

      final json = guest.toJson();
      final fromJson = UserProfile.fromJson(json);
      expect(fromJson.email, guest.email);
      expect(fromJson.activeChannelHandle, guest.activeChannelHandle);
      expect(fromJson.isGuest, isTrue);
    });

    test('UserProfile demo accounts list is populated and valid', () {
      final demos = UserProfile.demoAccounts();
      expect(demos.length, greaterThanOrEqualTo(3));
      expect(demos.first.id, 'usr_demo_alex_rc');
      expect(demos.first.connectedChannels.length, greaterThan(1));
    });

    test('BackendApiService register and login execution in mock mode', () async {
      final apiService = BackendApiService();
      apiService.setMockMode(true);

      final registered = await apiService.register(
        email: 'tester@studio.io',
        password: 'Password123',
        displayName: 'Test Creator',
        initialHandle: '@Fireship',
      );

      expect(registered.email, 'tester@studio.io');
      expect(registered.activeChannelHandle, '@Fireship');
      expect(registered.authToken, isNotNull);

      final loggedIn = await apiService.login(
        email: 'tester@studio.io',
        password: 'Password123',
      );
      expect(loggedIn.email, 'tester@studio.io');
      expect(loggedIn.authToken, isNotNull);
    });

    test('AuthService 1-Tap Google login and Demo switching', () async {
      final authService = AuthService();
      final googleUser = await authService.signInWithGoogle(
        preferredHandle: '@mkbhd',
      );
      expect(googleUser.isGuest, isFalse);
      expect(googleUser.id, startsWith('usr_'));
      expect(googleUser.activeChannelHandle, '@mkbhd');

      final demoAlex = UserProfile.demoAccounts().first;
      final switched = await authService.signInWithDemoProfile(demoAlex);
      expect(switched.displayName, contains('Alex Rivera'));
      expect(switched.connectedChannels, contains('@RevenueCat'));

      await authService.signOut();
      expect(authService.isAuthenticated, isFalse);
    });

    test('AuthService channel addition, switching and removal', () async {
      final authService = AuthService();
      await authService.signInWithGoogle();

      await authService.addChannel('@Fireship', isPro: true);
      expect(authService.currentUser!.connectedChannels, contains('@Fireship'));
      expect(authService.currentUser!.activeChannelHandle, '@Fireship');

      await authService.switchActiveChannel('@RevenueCat');
      expect(authService.currentUser!.activeChannelHandle, '@RevenueCat');

      await authService.removeChannel('@Fireship');
      expect(
        authService.currentUser!.connectedChannels.contains('@Fireship'),
        isFalse,
      );
    });

    test(
      'AuthProvider enforces Pro restriction for adding multiple channels',
      () async {
        final provider = AuthProvider();
        await provider.signOut();

        // Sign in as free user
        await provider.signInWithEmail(
          email: 'free@prevue.app',
          password: 'password123',
        );

        // Free user attempt to add 2nd channel without Pro
        final addedFree = await provider.addChannel(
          '@NewChannel',
          isPro: false,
        );
        expect(addedFree, isFalse);
        expect(provider.errorMessage, contains('requires Creator Pro'));

        // Pro user attempt
        final addedPro = await provider.addChannel('@NewChannel', isPro: true);
        expect(addedPro, isTrue);
        expect(provider.connectedChannels, contains('@NewChannel'));
      },
    );

    test(
      'AuthService persists user session to SharedPreferences and restores on reboot',
      () async {
        SharedPreferences.setMockInitialValues({});
        final service = AuthService();
        await service.signOut();
        expect(service.currentUser, isNull);

        // Sign in
        final user = await service.signInWithEmail(
          email: 'persisted.creator@studio.com',
          password: 'password123',
        );
        expect(user.email, 'persisted.creator@studio.com');

        // Verify stored in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('prevue_user_profile'), isNotNull);
        expect(prefs.getString('prevue_auth_token'), isNotNull);

        // Simulate app restart with new AuthService instance
        await service.signOut();
        expect(prefs.getString('prevue_user_profile'), isNull);
      },
    );

    testWidgets(
      'PrevueAPP auto-logs in directly into MainNavigationShell when session is persisted',
      (WidgetTester tester) async {
        final demoAlex = UserProfile.demoAccounts().first;
        SharedPreferences.setMockInitialValues({
          'prevue_user_profile': jsonEncode(demoAlex.toJson()),
          'prevue_auth_token': 'mock_jwt_demo_alex_rc',
        });

        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(const PrevueAPP());
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));

        // Verify that user bypassed AuthGateScreen and landed directly on Daily Briefing
        expect(find.text('Daily Briefing'), findsOneWidget);
        expect(find.text('Continue with Google'), findsNothing);
      },
    );
  });
}

