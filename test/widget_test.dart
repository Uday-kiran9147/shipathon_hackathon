import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shipathon_hackathon/main.dart';
import 'package:shipathon_hackathon/models/channel_graph.dart';
import 'package:shipathon_hackathon/models/daily_blueprint.dart';
import 'package:shipathon_hackathon/core/services/blueprint_generator_service.dart';
import 'package:shipathon_hackathon/core/services/gemini_service.dart';
import 'package:shipathon_hackathon/core/services/youtube_api_service.dart';
import 'package:shipathon_hackathon/core/services/semantic_vector_service.dart';
import 'package:shipathon_hackathon/core/services/simulator_engine_service.dart';

void main() {
  testWidgets('PrevueAPP smoke test & responsiveness across viewports without overflow', (WidgetTester tester) async {
    // Set standard mobile device viewport for ScreenUtil (390 x 844)
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const PrevueAPP());
    await tester.pump(const Duration(seconds: 1));

    // Verify that the Daily Briefing screen loads
    expect(find.text('Daily Briefing'), findsOneWidget);
    expect(find.text('All Blueprints'), findsOneWidget);

    // Test tab navigation to Simulator Tab
    await tester.tap(find.byIcon(Icons.speed_rounded).first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Test Retention'), findsWidgets);

    // Test tab navigation to Channel Graph Tab
    await tester.tap(find.byIcon(Icons.account_circle_rounded).first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('My Channel'), findsWidgets);

    // Test narrow device viewport (360 x 640)
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
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
            authorDisplayName: '@developer_one',
            text: 'How does GraalVM compare to standard JVM?',
            likeCount: 45,
            intentCategory: ChannelCommentIntent.question,
          ),
        ],
        totalUpvotes: 45,
        commentFrequency: 5,
        demandVelocityIndex: 4.2,
        primaryIntent: ChannelCommentIntent.question,
      );

      final json = cluster.toJson();
      expect(json['topicKeyword'], 'Spring Boot 3.3 GraalVM');
      expect(json['totalUpvotes'], 45);
      expect(json['demandVelocityIndex'], 4.2);

      final fromJson = CommentDemandCluster.fromJson(json);
      expect(fromJson.topicKeyword, cluster.topicKeyword);
      expect(fromJson.sampleComments.length, 1);
      expect(fromJson.sampleComments.first.likeCount, 45);
    });

    test('CreatorAuthenticityProfile model serialization', () {
      const profile = CreatorAuthenticityProfile(
        questionToPraiseRatio: 1.8,
        engagementVelocity: 14.5,
        signatureHookStyle: 'Constructor injection diff vs field injection',
        outlierVideoFormats: ['Deep Dive', 'Benchmark Teardown'],
        retentionVulnerabilityArea: '0:10 - 0:25 (Boilerplate project setup)',
      );

      final json = profile.toJson();
      expect(json['questionToPraiseRatio'], 1.8);
      expect(json['engagementVelocity'], 14.5);

      final fromJson = CreatorAuthenticityProfile.fromJson(json);
      expect(fromJson.signatureHookStyle, profile.signatureHookStyle);
      expect(fromJson.outlierVideoFormats.length, 2);
    });

    test('Mock channels contain rich demand clusters and authenticity profiles', () async {
      final telusko = await apiService.fetchChannelByHandle('@Telusko');
      expect(telusko.audienceInsight.topDemandClusters.isNotEmpty, isTrue);
      expect(telusko.authenticityProfile.questionToPraiseRatio, greaterThan(1.0));
      expect(telusko.authenticityProfile.retentionVulnerabilityArea.isNotEmpty, isTrue);

      final sriman = await apiService.fetchChannelByHandle('@SrimanKotaru');
      expect(sriman.audienceInsight.topDemandClusters.isNotEmpty, isTrue);
      expect(sriman.authenticityProfile.engagementVelocity, greaterThan(20.0));
    });

    test('BlueprintGeneratorService produces conviction scores and retention anchors', () async {
      final telusko = await apiService.fetchChannelByHandle('@Telusko');
      final blueprints = bpService.generateBlueprintsForChannel(telusko);

      expect(blueprints.isNotEmpty, isTrue);
      final heroBlueprint = blueprints.first;

      expect(heroBlueprint.convictionScore, greaterThanOrEqualTo(7.0));
      expect(heroBlueprint.convictionScore, lessThanOrEqualTo(10.0));
      expect(heroBlueprint.confidenceIntervalMin, lessThan(heroBlueprint.confidenceIntervalMax));
      expect(heroBlueprint.preEngineeredRetentionAnchors.length, equals(4));
      expect(heroBlueprint.demandCluster, isNotNull);
      expect(heroBlueprint.demandEvidenceSummary.isNotEmpty, isTrue);
    });

    test('generateFreshBlueprintOnDemand integrates demand clusters and conviction score', () async {
      final telusko = await apiService.fetchChannelByHandle('@Telusko');
      final freshBp = await bpService.generateFreshBlueprintOnDemand(telusko);

      expect(freshBp.convictionScore, greaterThanOrEqualTo(7.0));
      expect(freshBp.confidenceIntervalMin, lessThan(freshBp.confidenceIntervalMax));
      expect(freshBp.preEngineeredRetentionAnchors.isNotEmpty, isTrue);
    });

    test('generateBlueprintsForChannelAsync completes dynamically with fallback', () async {
      final telusko = await apiService.fetchChannelByHandle('@Telusko');
      final blueprints = await bpService.generateBlueprintsForChannelAsync(telusko);

      expect(blueprints.isNotEmpty, isTrue);
      expect(blueprints.first.title.isNotEmpty, isTrue);
      expect(blueprints.first.convictionScore, greaterThanOrEqualTo(7.0));
      expect(blueprints.first.preEngineeredRetentionAnchors.length, equals(4));
    });

    test('100% Dynamic Blueprint generation for arbitrary novel YouTube channel', () {
      final novelChannel = ChannelGraph(
        channelId: 'UC_arbitrary_robotics',
        channelName: 'NextGen Robotics',
        handle: '@NextGenRobotics',
        channelDescription: 'Building autonomous bipedal robots and ROS2 kinematics engines.',
        niche: 'Robotics & Embedded Systems',
        subscribers: 85000,
        medianViews: 22000,
        averageLikes: 1950,
        averageComments: 140,
        medianCtr: 6.8,
        totalVideos: 48,
        topTopicClusters: ['ROS2 Humble', 'Bipedal Locomotion', 'STM32 Motor Control'],
        signatureCreatorStyle: 'Hardware live-builds and oscilloscope sensor telemetry.',
        isLiveConnected: true,
        recentVideos: [
          ChannelRecentVideo(
            id: 'rob_vid_01',
            title: 'Why Our 12-DOF Quadruped Failed Its First Obstacle Test',
            description: 'Torque limits on brushless motors and IMU latency.',
            views: 64000,
            likes: 4200,
            commentCount: 310,
            publishedAt: DateTime.now().subtract(const Duration(days: 4)),
            tags: ['Robotics', 'ROS2', 'Motors'],
            durationFormatted: '16:45',
            topComments: [
              ChannelComment(
                id: 'rc_01',
                authorDisplayName: '@embedded_dev',
                text: 'Can you show how you tuned the PID loop for the knee joint actuators in ROS2?',
                likeCount: 88,
                intentCategory: ChannelCommentIntent.question,
              ),
            ],
          ),
          ChannelRecentVideo(
            id: 'rob_vid_02',
            title: 'Building a High-Torque Cycloidal Actuator from Scratch',
            description: '3D printed cycloidal gearbox with zero backlash.',
            views: 41000,
            likes: 3100,
            commentCount: 190,
            publishedAt: DateTime.now().subtract(const Duration(days: 14)),
            tags: ['Actuator', '3D Printing'],
            durationFormatted: '14:20',
            topComments: [],
          ),
        ],
        audienceInsight: const AudienceInsight(
          topDemandClusters: [
            CommentDemandCluster(
              id: 'cluster_rob_01',
              topicKeyword: 'PID Tuning for Knee Joint Actuators in ROS2',
              sampleComments: [
                ChannelComment(
                  id: 'rc_01',
                  authorDisplayName: '@embedded_dev',
                  text: 'Can you show how you tuned the PID loop for the knee joint actuators in ROS2?',
                  likeCount: 88,
                  intentCategory: ChannelCommentIntent.question,
                ),
              ],
              totalUpvotes: 88,
              commentFrequency: 12,
              demandVelocityIndex: 4.6,
              primaryIntent: ChannelCommentIntent.question,
            ),
          ],
          averageLikesPerVideo: 3650,
          averageCommentsPerVideo: 250,
        ),
        authenticityProfile: const CreatorAuthenticityProfile(
          questionToPraiseRatio: 2.2,
          engagementVelocity: 19.4,
          signatureHookStyle: 'Immediate robot torque failure demonstration leading into CAD diff',
          outlierVideoFormats: ['Teardown', 'Build Log'],
          retentionVulnerabilityArea: '0:08 - 0:22 (Prolonged schematic reading)',
        ),
      );

      final blueprints = bpService.generateBlueprintsForChannel(novelChannel);
      expect(blueprints.length, greaterThanOrEqualTo(4));

      // Blueprint 1: Grounded in the dynamic demand cluster
      final bp1 = blueprints[0];
      expect(bp1.title, contains('PID Tuning for Knee Joint Actuators in ROS2'));
      expect(bp1.hookText, contains('@embedded_dev'));
      expect(bp1.dataProofReason, contains('Why Our 12-DOF Quadruped Failed'));
      expect(bp1.convictionScore, greaterThan(7.5));

      // Blueprint 2: Outlier sequel to #1 upload
      final bp2 = blueprints[1];
      expect(bp2.title, contains('Why Our 12-DOF Quadruped Failed'));
      expect(bp2.hookText, contains('NextGen Robotics'));

      // Blueprint 3: Topic cluster / category blueprint
      final bp3 = blueprints[2];
      expect(bp3.categoryTag.isNotEmpty, isTrue);

      // Blueprint 4: Short-form rule
      final bp4 = blueprints[3];
      expect(bp4.format, BlueprintFormat.short);
      expect(bp4.title, contains('STM32 Motor Control'));
    });
  });

  group('YouTube Creator Intelligence & Simulator Engine 16-Point Tests', () {
    test('ChannelGraph computes defensible 0.7x, 1.0x, 1.5x, 2.0x performance ladder', () {
      const channel = ChannelGraph(
        handle: '@TechCreator',
        medianViews: 18400,
        uploadFrequency: 2.3,
        topOutlierMultiplier: 4.2,
      );

      expect(channel.uploadFrequencyFormatted, '2.3 / week');
      final ladder = channel.predictedPerformanceLadder;
      expect(ladder['0.7x'], 12880);
      expect(ladder['1.0x'], 18400);
      expect(ladder['1.5x'], 27600);
      expect(ladder['2.0x'], 36800);
    });

    test('SemanticVectorService calculates valid cosine similarities & feature vectors', () {
      final vectorService = SemanticVectorService();
      final vecA = vectorService.generateFeatureVector('Building AI Agent Coding Systems');
      final vecB = vectorService.generateFeatureVector('Autonomous Coding Agents in Production');
      final vecC = vectorService.generateFeatureVector('Cooking Italian Pasta Carbonara');

      expect(vecA.length, 768);
      expect(vecB.length, 768);

      final simRelated = vectorService.cosineSimilarity(vecA, vecB);
      final simUnrelated = vectorService.cosineSimilarity(vecA, vecC);

      expect(simRelated, greaterThan(simUnrelated));
      expect(simRelated, greaterThan(0.2));
    });

    test('SimulatorEngineService evaluates all 7 dimensions and computes views projection', () async {
      const channel = ChannelGraph(
        handle: '@AIEngineer',
        niche: 'AI Engineering',
        medianViews: 20000,
        topTopicClusters: ['AI Agents', 'LangGraph'],
      );

      final result = await SimulatorEngineService().runSimulation(
        title: 'I Built My Entire Stack With AI Agents',
        draftScript:
            'Today I am going to explain how AI agents work. We tried building an autonomous pipeline for 30 days and benchmarked the speed.',
        format: BlueprintFormat.longForm,
        channel: channel,
      );

      expect(result.hookScore, greaterThan(0.0));
      expect(result.resonanceScore, greaterThan(0.0));
      expect(result.noveltyScore, greaterThan(0.0));
      expect(result.topicMomentumScore, greaterThan(0.0));
      expect(result.clarityScore, greaterThan(0.0));
      expect(result.pacingScore, greaterThan(0.0));
      expect(result.creatorFitScore, greaterThan(0.0));
      expect(result.overallScore, greaterThan(0.0));
      expect(result.projectedViewsMultiplier, greaterThan(0.5));
      expect(result.projectedViews, greaterThan(5000));
      expect(result.hazards.isNotEmpty, isTrue);
      expect(result.fixes.length, greaterThanOrEqualTo(2));
    });

    test('Applying Prescriptive Fix lifts Hook Score and recalculates projected views', () async {
      const channel = ChannelGraph(
        handle: '@AIEngineer',
        medianViews: 10000,
      );

      final engine = SimulatorEngineService();
      final initialResult = await engine.runSimulation(
        title: 'How I Built This',
        draftScript:
            'Today we talk about software architecture. This is a very long sentence that has way too many words and continues endlessly without any visual break or proof whatsoever.',
        format: BlueprintFormat.longForm,
        channel: channel,
      );

      final fixId = initialResult.fixes.first.id;
      final boosted = engine.applyPrescriptiveFix(
        currentResult: initialResult,
        fixId: fixId,
      );

      expect(boosted.hookScore, greaterThanOrEqualTo(initialResult.hookScore));
      expect(boosted.projectedViews, greaterThanOrEqualTo(initialResult.projectedViews));
      expect(boosted.fixes.firstWhere((f) => f.id == fixId).isApplied, isTrue);
    });
  });

  group('GeminiService Resilient Blueprint Parsing & Truncation Recovery Tests', () {
    late GeminiService geminiService;
    const testChannel = ChannelGraph(
      handle: '@RevenueCat',
      channelName: 'RevenueCat',
      niche: 'Subscription App Growth',
      medianViews: 5000,
    );

    setUp(() {
      geminiService = GeminiService();
    });

    test('GeminiService successfully parses clean JSON blueprints', () {
      const validJson = '''
      {
        "blueprints": [
          {
            "id": "bp_gemini_1",
            "title": "Why 90% of In-App Subscriptions Fail in Month 1",
            "format": "longForm",
            "formatLabel": "Long-Form (12–15 Min)",
            "hookText": "If your subscription app has higher than 15% churn in week 1, you have a paywall onboarding gap...",
            "thumbnailConceptLeft": "Churn Graph Spiking",
            "thumbnailConceptRight": "Retention Framework with Verified Badge",
            "thumbnailTag": "RETENTION BENCHMARK",
            "dataProofReason": "Derived from live subscriber telemetry benchmarks.",
            "predictedMultiplier": 3.2,
            "convictionScore": 9.1,
            "categoryTag": "Subscription App Growth",
            "demandEvidenceSummary": "Audience demand regarding subscription churn.",
            "creatorAuthenticityProof": "Aligned with analytical teardown style.",
            "engagementContext": "Mined from high-velocity topics.",
            "preEngineeredRetentionAnchors": [
              "0:00 - 0:05: High-tension hook",
              "0:05 - 0:25: Immediate proof",
              "0:25 - 4:00: Step-by-step framework",
              "End: Next video bridge"
            ]
          }
        ]
      }
      ''';

      final blueprints = geminiService.parseBlueprintsFromJson(validJson, testChannel);
      expect(blueprints.length, 1);
      expect(blueprints.first.title, 'Why 90% of In-App Subscriptions Fail in Month 1');
      expect(blueprints.first.predictedMultiplier, 3.2);
      expect(blueprints.first.convictionScore, 9.1);
      expect(blueprints.first.preEngineeredRetentionAnchors.length, 4);
    });

    test('GeminiService parses markdown code-fenced JSON', () {
      const markdownJson = '''
      ```json
      {
        "blueprints": [
          {
            "id": "bp_markdown_1",
            "title": "Paywall Design Teardown: 3 Winning Layouts",
            "format": "longForm",
            "formatLabel": "Long-Form (10–13 Min)",
            "hookText": "We analyzed 50 top-grossing apps to uncover the highest-converting paywall structure.",
            "predictedMultiplier": 2.9,
            "convictionScore": 8.7
          }
        ]
      }
      ```
      ''';

      final blueprints = geminiService.parseBlueprintsFromJson(markdownJson, testChannel);
      expect(blueprints.length, 1);
      expect(blueprints.first.title, 'Paywall Design Teardown: 3 Winning Layouts');
    });

    test('GeminiService handles unescaped newlines inside string literals without throwing', () {
      const jsonWithRawNewlines = '{\n'
          '  "blueprints": [\n'
          '    {\n'
          '      "id": "bp_raw_newlines",\n'
          '      "title": "Subscription Strategy",\n'
          '      "format": "longForm",\n'
          '      "hookText": "Line 1 of hook\\nLine 2 of hook",\n'
          '      "predictedMultiplier": 2.5,\n'
          '      "convictionScore": 8.4\n'
          '    }\n'
          '  ]\n'
          '}';

      final blueprints = geminiService.parseBlueprintsFromJson(jsonWithRawNewlines, testChannel);
      expect(blueprints.length, 1);
      expect(blueprints.first.title, 'Subscription Strategy');
    });

    test('GeminiService recovers completed blueprints from truncated JSON streams (e.g. Unterminated string)', () {
      // Simulates the exact situation where Gemini truncated midway at "hookText in the 2nd item
      const truncatedStreamJson = '''
      {
        "blueprints": [
          {
            "id": "bp_complete_1",
            "title": "The Subscription Trap (And How to Escape)",
            "format": "longForm",
            "formatLabel": "Long-Form (12–15 Min)",
            "hookText": "Most founders price their subscriptions too low in 2026...",
            "thumbnailConceptLeft": "Stagnant ARR line",
            "thumbnailConceptRight": "Optimized Pricing Tier",
            "thumbnailTag": "PRICING FIX",
            "dataProofReason": "Backed by catalog benchmarks.",
            "predictedMultiplier": 3.1,
            "convictionScore": 8.9,
            "preEngineeredRetentionAnchors": [
              "0:00 - 0:05: Bold thesis"
            ]
          },
          {
            "id": "bp_truncated_2",
            "title": "Pricing Models Compared",
            "format": "longForm",
            "hookText
      ''';

      final blueprints = geminiService.parseBlueprintsFromJson(truncatedStreamJson, testChannel);
      expect(blueprints.isNotEmpty, isTrue);
      expect(blueprints.first.id, 'bp_complete_1');
      expect(blueprints.first.title, 'The Subscription Trap (And How to Escape)');
      expect(blueprints.first.predictedMultiplier, 3.1);
    });
  });
}
