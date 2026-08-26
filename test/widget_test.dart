import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shipathon_hackathon/main.dart';
import 'package:shipathon_hackathon/models/channel_graph.dart';
import 'package:shipathon_hackathon/models/daily_blueprint.dart';
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
}
