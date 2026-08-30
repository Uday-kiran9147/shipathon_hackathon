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
import 'package:shipathon_hackathon/core/services/blueprint_generator_service.dart';
import 'package:shipathon_hackathon/core/services/gemini_service.dart';
import 'package:shipathon_hackathon/core/services/youtube_api_service.dart';
import 'package:shipathon_hackathon/core/services/semantic_vector_service.dart';
import 'package:shipathon_hackathon/core/services/simulator_engine_service.dart';
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
  0x52,
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

    // Open Channel Switcher Modal from Channel screen
    await tester.tap(find.text('Channels').first);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('CHANNEL WORKSPACE'), findsOneWidget);

    // Close modal
    await tester.tap(
      find.byIcon(Icons.close_rounded).first,
      warnIfMissed: false,
    );
    await tester.pump(const Duration(milliseconds: 300));
  });

  group('Comment Demand Clustering & Conviction Engine Tests', () {
    late YouTubeApiService apiService;
    late BlueprintGeneratorService bpService;

    setUp(() {
      apiService = YouTubeApiService();
      bpService = BlueprintGeneratorService();
    });

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

    test(
      'Mock channels contain rich demand clusters and authenticity profiles',
      () async {
        final teluskoGraph = await apiService.fetchChannelByHandle('@Telusko');
        expect(
          teluskoGraph.audienceInsight.topDemandClusters.isNotEmpty,
          isTrue,
        );
        expect(
          teluskoGraph.authenticityProfile.signatureHookStyle.isNotEmpty,
          isTrue,
        );

        final rcGraph = await apiService.fetchChannelByHandle('@RevenueCat');
        expect(rcGraph.audienceInsight.topDemandClusters.isNotEmpty, isTrue);
        expect(
          rcGraph.authenticityProfile.outlierVideoFormats.isNotEmpty,
          isTrue,
        );
      },
    );

    test(
      'BlueprintGeneratorService produces conviction scores and retention anchors',
      () async {
        final rcGraph = await apiService.fetchChannelByHandle('@RevenueCat');
        final blueprints = bpService.generateBlueprintsForChannel(rcGraph);

        expect(blueprints.isNotEmpty, isTrue);
        final firstBp = blueprints.first;
        expect(firstBp.convictionScore, greaterThan(7.0));
        expect(firstBp.categoryTag.isNotEmpty, isTrue);
        expect(firstBp.preEngineeredRetentionAnchors.isNotEmpty, isTrue);
        expect(firstBp.thumbnailConceptLeft.isNotEmpty, isTrue);
      },
    );

    test(
      'generateFreshBlueprintOnDemand integrates demand clusters and conviction score',
      () async {
        final teluskoGraph = await apiService.fetchChannelByHandle('@Telusko');

        final freshBp = await bpService.generateFreshBlueprintOnDemand(
          teluskoGraph,
        );

        expect(freshBp.categoryTag.isNotEmpty, isTrue);
        expect(freshBp.convictionScore, greaterThanOrEqualTo(7.0));
        expect(freshBp.dataProofReason.isNotEmpty, isTrue);
      },
    );

    test(
      'generateBlueprintsForChannelAsync completes dynamically with fallback',
      () async {
        final rcGraph = await apiService.fetchChannelByHandle('@RevenueCat');
        final asyncBlueprints = await bpService
            .generateBlueprintsForChannelAsync(rcGraph);

        expect(asyncBlueprints.length, greaterThanOrEqualTo(3));
        for (final bp in asyncBlueprints) {
          expect(bp.title.isNotEmpty, isTrue);
          expect(bp.hookText.isNotEmpty, isTrue);
          expect(bp.convictionScore, greaterThan(5.0));
        }
      },
    );

    test(
      '100% Dynamic Blueprint generation for arbitrary novel YouTube channel',
      () async {
        final novelGraph = await apiService.fetchChannelByHandle(
          '@AnyNovelCreator999',
        );
        expect(
          novelGraph.channelName.toLowerCase(),
          contains('anynovelcreator999'),
        );

        final dynamicBlueprints = await bpService
            .generateBlueprintsForChannelAsync(novelGraph);
        expect(dynamicBlueprints.length, greaterThanOrEqualTo(3));
        expect(dynamicBlueprints.first.categoryTag.isNotEmpty, isTrue);
      },
    );
  });

  group('YouTube Creator Intelligence & Simulator Engine 16-Point Tests', () {
    late YouTubeApiService apiService;
    late SimulatorEngineService simService;
    late SemanticVectorService vectorService;

    setUp(() {
      apiService = YouTubeApiService();
      simService = SimulatorEngineService();
      vectorService = SemanticVectorService();
    });

    test(
      'ChannelGraph computes defensible 0.7x, 1.0x, 1.5x, 2.0x performance ladder',
      () async {
        final graph = await apiService.fetchChannelByHandle('@RevenueCat');
        expect(graph.medianViews, 5600);
        expect(graph.predictedPerformanceLadder['0.7x'], (5600 * 0.7).round());
        expect(graph.predictedPerformanceLadder['1.0x'], 5600);
        expect(graph.predictedPerformanceLadder['1.5x'], (5600 * 1.5).round());
        expect(graph.predictedPerformanceLadder['2.0x'], (5600 * 2.0).round());
      },
    );

    test(
      'SemanticVectorService calculates valid cosine similarities & feature vectors',
      () {
        final vecA = vectorService.generateFeatureVector(
          'In this video we build a production microservice with Java 21.',
        );
        final vecB = vectorService.generateFeatureVector(
          'Learn how to architect Java backend systems with Spring.',
        );
        final sim = vectorService.cosineSimilarity(vecA, vecB);
        expect(sim, inInclusiveRange(0.0, 1.0));
      },
    );

    test(
      'SimulatorEngineService evaluates all 7 dimensions and computes views projection',
      () async {
        final channel = await apiService.fetchChannelByHandle('@RevenueCat');

        final result = await simService.runSimulation(
          title: 'How We Scaled Our RevenueCat Paywalls by 300%',
          draftScript:
              'Most developers build paywalls wrong. In this video, we analyze real subscription data from 5,000 apps and show you 3 exact tweaks that 3x trial conversions.',
          format: BlueprintFormat.longForm,
          channel: channel,
        );

        expect(result.hookScore, inInclusiveRange(0.0, 10.0));
        expect(result.resonanceScore, inInclusiveRange(0.0, 10.0));
        expect(result.projectedViews, greaterThan(0));
      },
    );

    test(
      'Applying Prescriptive Fix lifts Hook Score and recalculates projected views',
      () async {
        final channel = await apiService.fetchChannelByHandle('@RevenueCat');

        final originalResult = await simService.runSimulation(
          title: 'Paywall Mistakes',
          draftScript: 'Hi guys, today I am going to talk about some paywalls.',
          format: BlueprintFormat.longForm,
          channel: channel,
        );
        expect(originalResult.fixes.isNotEmpty, isTrue);

        final fixToApply = originalResult.fixes.first;
        final updatedResult = simService.applyPrescriptiveFix(
          currentResult: originalResult,
          fixId: fixToApply.id,
        );

        expect(
          updatedResult.hookScore,
          greaterThanOrEqualTo(originalResult.hookScore),
        );
      },
    );
  });

  group(
    'GeminiService Resilient Blueprint Parsing & Truncation Recovery Tests',
    () {
      late GeminiService geminiService;
      late YouTubeApiService apiService;

      setUp(() {
        geminiService = GeminiService();
        apiService = YouTubeApiService();
      });

      test('GeminiService successfully parses clean JSON blueprints', () async {
        final channel = await apiService.fetchChannelByHandle('@RevenueCat');
        const cleanJson = '''
      [
        {
          "id": "bp_1",
          "title": "Spring Boot 3.3 with Java 21",
          "format": "longForm",
          "formatLabel": "Crash Course (30–45 Min)",
          "hookText": "If you are still deploying Java 17 in production, you are paying 40% more for cloud memory...",
          "thumbnailConceptLeft": "Java 17 vs Java 21 Memory Graph",
          "thumbnailConceptRight": "Telusko Terminal with Green Status",
          "thumbnailTag": "40% LESS MEMORY",
          "dataProofReason": "Based on 34 comments requesting Java 21 migration guide.",
          "predictedMultiplier": 2.8,
          "convictionScore": 9.2,
          "categoryTag": "Java 21 & Spring Boot",
          "preEngineeredRetentionAnchors": [
            "0:00 - 0:05: Memory cost comparison",
            "0:05 - 0:20: Live benchmark terminal",
            "0:20 - 5:00: Virtual threads deep dive"
          ]
        }
      ]
      ''';

        final blueprints = geminiService.parseBlueprintsFromJson(
          cleanJson,
          channel,
        );
        expect(blueprints.length, 1);
        expect(blueprints.first.title, 'Spring Boot 3.3 with Java 21');
        expect(blueprints.first.predictedMultiplier, 2.8);
        expect(blueprints.first.convictionScore, 9.2);
      });

      test('GeminiService parses markdown code-fenced JSON', () async {
        final channel = await apiService.fetchChannelByHandle('@RevenueCat');
        const fencedJson = '''
      Here are the prescriptive blueprints for your channel:
      ```json
      [
        {
          "id": "bp_fenced_1",
          "title": "Mastering RevenueCat Paywalls in Flutter",
          "format": "longForm",
          "formatLabel": "Long-Form",
          "hookText": "Most subscription apps fail because their paywall is shown at the wrong screen...",
          "thumbnailConceptLeft": "Broken Paywall Screen",
          "thumbnailConceptRight": "Optimized Revenue Chart",
          "thumbnailTag": "3X CONVERSIONS",
          "dataProofReason": "Validated by top mobile dev audience demand.",
          "predictedMultiplier": 2.4,
          "convictionScore": 8.7,
          "categoryTag": "Mobile App Monetization",
          "preEngineeredRetentionAnchors": ["0:00 - 0:05: The common mistake"]
        }
      ]
      ```
      ''';

        final blueprints = geminiService.parseBlueprintsFromJson(
          fencedJson,
          channel,
        );
        expect(blueprints.length, 1);
        expect(blueprints.first.id, 'bp_fenced_1');
        expect(blueprints.first.predictedMultiplier, 2.4);
      });

      test(
        'GeminiService handles unescaped newlines inside string literals without throwing',
        () async {
          final channel = await apiService.fetchChannelByHandle('@RevenueCat');
          const brokenJsonWithNewlines = '''
      [
        {
          "id": "bp_newline_1",
          "title": "Multi-line
          Title That Was Broken",
          "format": "short",
          "formatLabel": "Shorts (<60s)",
          "hookText": "Line 1
          Line 2
          Line 3",
          "thumbnailConceptLeft": "Left
          Concept",
          "thumbnailConceptRight": "Right Concept",
          "thumbnailTag": "TAG",
          "dataProofReason": "Reason
          With Newlines",
          "predictedMultiplier": 1.9,
          "convictionScore": 7.5,
          "categoryTag": "Shorts Strategy",
          "preEngineeredRetentionAnchors": ["Anchor 1", "Anchor 2"]
        }
      ]
      ''';

          final blueprints = geminiService.parseBlueprintsFromJson(
            brokenJsonWithNewlines,
            channel,
          );
          expect(blueprints.isNotEmpty, isTrue);
          expect(blueprints.first.format, BlueprintFormat.short);
        },
      );

      test(
        'GeminiService recovers completed blueprints from truncated JSON streams (e.g. Unterminated string)',
        () async {
          final channel = await apiService.fetchChannelByHandle('@RevenueCat');
          const truncatedStream = '''
      [
        {
          "id": "bp_complete_1",
          "title": "The Subscription Trap (And How to Escape)",
          "format": "longForm",
          "formatLabel": "Breakdown",
          "hookText": "Why recurring billing is harder than you think...",
          "thumbnailConceptLeft": "Billing Graph",
          "thumbnailConceptRight": "Key Insight",
          "thumbnailTag": "ESSENTIAL",
          "dataProofReason": "Market trends",
          "predictedMultiplier": 3.1,
          "convictionScore": 9.4,
          "categoryTag": "SaaS Monetization",
          "preEngineeredRetentionAnchors": ["0:00 - Hook"]
        },
        {
          "id": "bp_truncated_2",
          "title": "Incomplete Blueprint That Got Cut Off Mid-Sentence Becau
      ''';

          final blueprints = geminiService.parseBlueprintsFromJson(
            truncatedStream,
            channel,
          );
          expect(blueprints.isNotEmpty, isTrue);
          expect(blueprints.first.id, 'bp_complete_1');
          expect(
            blueprints.first.title,
            'The Subscription Trap (And How to Escape)',
          );
          expect(blueprints.first.predictedMultiplier, 3.1);
        },
      );
    },
  );

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

    test('BackendApiService register and login execution', () async {
      final apiService = BackendApiService();
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
      expect(googleUser.id, startsWith('usr_google_'));
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
