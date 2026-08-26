import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shipathon_hackathon/main.dart';
import 'package:shipathon_hackathon/models/channel_graph.dart';
import 'package:shipathon_hackathon/core/services/blueprint_generator_service.dart';
import 'package:shipathon_hackathon/core/services/youtube_api_service.dart';

void main() {
  testWidgets('PrevueAPP smoke test', (WidgetTester tester) async {
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
  });
}
