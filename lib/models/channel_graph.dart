/// Model for a recent video fetched live from the creator's YouTube channel
class ChannelRecentVideo {
  final String id;
  final String title;
  final int views;
  final DateTime publishedAt;
  final String? thumbnailUrl;

  const ChannelRecentVideo({
    required this.id,
    required this.title,
    required this.views,
    required this.publishedAt,
    this.thumbnailUrl,
  });

  factory ChannelRecentVideo.fromJson(Map<String, dynamic> json) {
    return ChannelRecentVideo(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Video',
      views: json['views'] as int? ?? 0,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }
}

/// Channel Graph Baseline model defining the creator's context engine
class ChannelGraph {
  final String? channelId;
  final String channelName;
  final String handle;
  final String niche;
  final int subscribers;
  final int medianViews;
  final double medianCtr;
  final int totalVideos;
  final String targetAudienceLevel;
  final List<String> topTopicClusters;
  final String topFormat;
  final String? avatarUrl;
  final bool isLiveConnected;
  final List<ChannelRecentVideo> recentVideos;

  const ChannelGraph({
    this.channelId,
    this.channelName = '',
    required this.handle,
    this.niche = '',
    this.subscribers = 0,
    this.medianViews = 0,
    this.medianCtr = 0.0,
    this.totalVideos = 0,
    this.targetAudienceLevel = '',
    this.topTopicClusters = const [],
    this.topFormat = 'Long-Form + Shorts',
    this.avatarUrl,
    this.isLiveConnected = false,
    this.recentVideos = const [],
  });

  /// Check if the channel graph contains synced live data
  bool get isConfigured =>
      handle.isNotEmpty && (subscribers > 0 || isLiveConnected);

  ChannelGraph copyWith({
    String? channelId,
    String? channelName,
    String? handle,
    String? niche,
    int? subscribers,
    int? medianViews,
    double? medianCtr,
    int? totalVideos,
    String? targetAudienceLevel,
    List<String>? topTopicClusters,
    String? topFormat,
    String? avatarUrl,
    bool? isLiveConnected,
    List<ChannelRecentVideo>? recentVideos,
  }) {
    return ChannelGraph(
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      handle: handle ?? this.handle,
      niche: niche ?? this.niche,
      subscribers: subscribers ?? this.subscribers,
      medianViews: medianViews ?? this.medianViews,
      medianCtr: medianCtr ?? this.medianCtr,
      totalVideos: totalVideos ?? this.totalVideos,
      targetAudienceLevel: targetAudienceLevel ?? this.targetAudienceLevel,
      topTopicClusters: topTopicClusters ?? this.topTopicClusters,
      topFormat: topFormat ?? this.topFormat,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isLiveConnected: isLiveConnected ?? this.isLiveConnected,
      recentVideos: recentVideos ?? this.recentVideos,
    );
  }
}
