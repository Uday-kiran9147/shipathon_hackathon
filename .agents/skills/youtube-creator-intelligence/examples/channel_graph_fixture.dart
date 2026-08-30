// Example Reference: Dynamic Channel Graph Fixture Generation
import 'package:shipathon_hackathon/models/channel_graph.dart';

class ChannelGraphFixture {
  static ChannelGraph createSampleChannel({
    String handle = '@TechExplorer',
    String channelName = 'Tech Explorer',
    int medianViews = 15000,
  }) {
    return ChannelGraph(
      channelId: 'UC_sample_fixture_01',
      channelName: channelName,
      handle: handle,
      channelDescription: 'Hands-on benchmarks, code teardowns, and architecture deep dives.',
      niche: 'Software Engineering',
      subscribers: 45000,
      medianViews: medianViews,
      averageLikes: 1200,
      averageComments: 85,
      medianCtr: 6.4,
      totalVideos: 62,
      topTopicClusters: ['Flutter Performance', 'Dart 3 Patterns', 'State Management'],
      signatureCreatorStyle: 'Fast-paced IDE walkthrough with live benchmarks.',
      isLiveConnected: true,
    );
  }
}
