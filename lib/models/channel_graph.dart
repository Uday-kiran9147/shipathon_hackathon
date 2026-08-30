/// Categories of viewer intent identified from YouTube comments
enum ChannelCommentIntent {
  request,
  question,
  feedback,
  praise,
  discussion,
}

/// Model for a live viewer comment fetched from YouTube commentThreads API
class ChannelComment {
  final String id;
  final String authorDisplayName;
  final String? authorProfileImageUrl;
  final String text;
  final int likeCount;
  final DateTime? publishedAt;
  final ChannelCommentIntent intentCategory;
  final bool isPinned;

  const ChannelComment({
    required this.id,
    required this.authorDisplayName,
    this.authorProfileImageUrl,
    required this.text,
    this.likeCount = 0,
    this.publishedAt,
    this.intentCategory = ChannelCommentIntent.discussion,
    this.isPinned = false,
  });

  factory ChannelComment.fromJson(Map<String, dynamic> json) {
    final intentStr = json['intentCategory'] as String? ?? 'discussion';
    final intent = ChannelCommentIntent.values.firstWhere(
      (e) => e.name == intentStr,
      orElse: () => ChannelCommentIntent.discussion,
    );

    return ChannelComment(
      id: json['id'] as String? ?? '',
      authorDisplayName: json['authorDisplayName'] as String? ?? 'Viewer',
      authorProfileImageUrl: json['authorProfileImageUrl'] as String?,
      text: json['text'] as String? ?? '',
      likeCount: json['likeCount'] as int? ?? 0,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'] as String)
          : null,
      intentCategory: intent,
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorDisplayName': authorDisplayName,
        'authorProfileImageUrl': authorProfileImageUrl,
        'text': text,
        'likeCount': likeCount,
        'publishedAt': publishedAt?.toIso8601String(),
        'intentCategory': intentCategory.name,
        'isPinned': isPinned,
      };
}

/// Semantic cluster of multiple audience comments expressing identical demand
class CommentDemandCluster {
  final String id;
  final String topicKeyword;
  final List<ChannelComment> sampleComments;
  final int totalUpvotes;
  final int commentFrequency;
  final double demandVelocityIndex; // DVI: frequency * log(likes+1) weighted
  final ChannelCommentIntent primaryIntent;

  const CommentDemandCluster({
    required this.id,
    required this.topicKeyword,
    this.sampleComments = const [],
    this.totalUpvotes = 0,
    this.commentFrequency = 1,
    this.demandVelocityIndex = 1.0,
    this.primaryIntent = ChannelCommentIntent.request,
  });

  factory CommentDemandCluster.fromJson(Map<String, dynamic> json) {
    final rawComments = json['sampleComments'] as List<dynamic>? ?? [];
    final comments = rawComments
        .map((c) => ChannelComment.fromJson(c as Map<String, dynamic>))
        .toList();
    final intentStr = json['primaryIntent'] as String? ?? 'request';
    final intent = ChannelCommentIntent.values.firstWhere(
      (e) => e.name == intentStr,
      orElse: () => ChannelCommentIntent.request,
    );

    return CommentDemandCluster(
      id: json['id'] as String? ?? '',
      topicKeyword: json['topicKeyword'] as String? ?? '',
      sampleComments: comments,
      totalUpvotes: json['totalUpvotes'] as int? ?? 0,
      commentFrequency: json['commentFrequency'] as int? ?? 1,
      demandVelocityIndex:
          (json['demandVelocityIndex'] as num?)?.toDouble() ?? 1.0,
      primaryIntent: intent,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'topicKeyword': topicKeyword,
        'sampleComments': sampleComments.map((c) => c.toJson()).toList(),
        'totalUpvotes': totalUpvotes,
        'commentFrequency': commentFrequency,
        'demandVelocityIndex': demandVelocityIndex,
        'primaryIntent': primaryIntent.name,
      };
}

/// Creator DNA & Niche Authenticity Profile
class CreatorAuthenticityProfile {
  final double questionToPraiseRatio; // Educational trust & authority indicator
  final double engagementVelocity; // Likes + Comments per 1K Views
  final String signatureHookStyle;
  final List<String> outlierVideoFormats;
  final String retentionVulnerabilityArea;

  const CreatorAuthenticityProfile({
    this.questionToPraiseRatio = 1.0,
    this.engagementVelocity = 5.2,
    this.signatureHookStyle =
        'Data-backed tension with immediate code/case proof',
    this.outlierVideoFormats = const [
      'Deep Dive Masterclass',
      'Teardown & Benchmark'
    ],
    this.retentionVulnerabilityArea =
        '0:12 - 0:18 (Explanatory lull before solution)',
  });

  factory CreatorAuthenticityProfile.fromJson(Map<String, dynamic> json) {
    return CreatorAuthenticityProfile(
      questionToPraiseRatio:
          (json['questionToPraiseRatio'] as num?)?.toDouble() ?? 1.0,
      engagementVelocity:
          (json['engagementVelocity'] as num?)?.toDouble() ?? 5.2,
      signatureHookStyle: json['signatureHookStyle'] as String? ??
          'Data-backed tension with immediate code/case proof',
      outlierVideoFormats: (json['outlierVideoFormats'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['Deep Dive Masterclass', 'Teardown & Benchmark'],
      retentionVulnerabilityArea: json['retentionVulnerabilityArea']
              as String? ??
          '0:12 - 0:18 (Explanatory lull before solution)',
    );
  }

  Map<String, dynamic> toJson() => {
        'questionToPraiseRatio': questionToPraiseRatio,
        'engagementVelocity': engagementVelocity,
        'signatureHookStyle': signatureHookStyle,
        'outlierVideoFormats': outlierVideoFormats,
        'retentionVulnerabilityArea': retentionVulnerabilityArea,
      };
}

/// Model for a recent video fetched live from the creator's YouTube channel
class ChannelRecentVideo {
  final String id;
  final String title;
  final String description;
  final int views;
  final int likes;
  final int commentCount;
  final DateTime publishedAt;
  final String? thumbnailUrl;
  final List<String> tags;
  final String durationFormatted;
  final List<ChannelComment> topComments;

  const ChannelRecentVideo({
    required this.id,
    required this.title,
    this.description = '',
    required this.views,
    this.likes = 0,
    this.commentCount = 0,
    required this.publishedAt,
    this.thumbnailUrl,
    this.tags = const [],
    this.durationFormatted = '10:00',
    this.topComments = const [],
  });

  /// Calculate engagement percentage: (likes + comments) / views
  double get engagementRate {
    if (views <= 0) return 0.0;
    return ((likes + commentCount) / views) * 100;
  }

  /// Top audience requests mined from this video's comments
  List<ChannelComment> get commentRequests => topComments
      .where((c) =>
          c.intentCategory == ChannelCommentIntent.request ||
          c.intentCategory == ChannelCommentIntent.question)
      .toList();

  factory ChannelRecentVideo.fromJson(Map<String, dynamic> json) {
    final rawComments = json['topComments'] as List<dynamic>? ?? [];
    final comments = rawComments
        .map((c) => ChannelComment.fromJson(c as Map<String, dynamic>))
        .toList();

    return ChannelRecentVideo(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Video',
      description: json['description'] as String? ?? '',
      views: json['views'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((t) => t.toString())
              .toList() ??
          [],
      durationFormatted: json['durationFormatted'] as String? ?? '10:00',
      topComments: comments,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'views': views,
        'likes': likes,
        'commentCount': commentCount,
        'publishedAt': publishedAt.toIso8601String(),
        'thumbnailUrl': thumbnailUrl,
        'tags': tags,
        'durationFormatted': durationFormatted,
        'topComments': topComments.map((c) => c.toJson()).toList(),
      };
}

/// Audience synthesis and comment intelligence summary
class AudienceInsight {
  final List<String> topViewerRequests;
  final List<ChannelComment> topAudienceQuestions;
  final List<CommentDemandCluster> topDemandClusters;
  final List<String> praiseKeywords;
  final int averageLikesPerVideo;
  final int averageCommentsPerVideo;
  final String topPerformingTopic;

  const AudienceInsight({
    this.topViewerRequests = const [],
    this.topAudienceQuestions = const [],
    this.topDemandClusters = const [],
    this.praiseKeywords = const [],
    this.averageLikesPerVideo = 0,
    this.averageCommentsPerVideo = 0,
    this.topPerformingTopic = '',
  });

  factory AudienceInsight.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['topAudienceQuestions'] as List<dynamic>? ?? [];
    final questions = rawQuestions
        .map((q) => ChannelComment.fromJson(q as Map<String, dynamic>))
        .toList();
    final rawClusters = json['topDemandClusters'] as List<dynamic>? ?? [];
    final clusters = rawClusters
        .map((c) => CommentDemandCluster.fromJson(c as Map<String, dynamic>))
        .toList();

    return AudienceInsight(
      topViewerRequests: (json['topViewerRequests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      topAudienceQuestions: questions,
      topDemandClusters: clusters,
      praiseKeywords: (json['praiseKeywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      averageLikesPerVideo: json['averageLikesPerVideo'] as int? ?? 0,
      averageCommentsPerVideo: json['averageCommentsPerVideo'] as int? ?? 0,
      topPerformingTopic: json['topPerformingTopic'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'topViewerRequests': topViewerRequests,
        'topAudienceQuestions':
            topAudienceQuestions.map((q) => q.toJson()).toList(),
        'topDemandClusters': topDemandClusters.map((c) => c.toJson()).toList(),
        'praiseKeywords': praiseKeywords,
        'averageLikesPerVideo': averageLikesPerVideo,
        'averageCommentsPerVideo': averageCommentsPerVideo,
        'topPerformingTopic': topPerformingTopic,
      };
}

/// Topic Performance Multiplier relative to channel median views
class TopicPerformanceMultiplier {
  final String topic;
  final double multiple; // e.g. 2.4x median
  final int videoCount;
  final int averageViews;

  const TopicPerformanceMultiplier({
    required this.topic,
    required this.multiple,
    this.videoCount = 1,
    this.averageViews = 0,
  });

  factory TopicPerformanceMultiplier.fromJson(Map<String, dynamic> json) {
    return TopicPerformanceMultiplier(
      topic: json['topic'] as String? ?? '',
      multiple: (json['multiple'] as num?)?.toDouble() ?? 1.0,
      videoCount: json['videoCount'] as int? ?? 1,
      averageViews: json['averageViews'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'multiple': multiple,
        'videoCount': videoCount,
        'averageViews': averageViews,
      };
}

/// Channel Graph Baseline model defining the creator's context engine
class ChannelGraph {
  final String? channelId;
  final String channelName;
  final String handle;
  final String channelDescription;
  final String niche;
  final int subscribers;
  final int medianViews;
  final int averageLikes;
  final int averageComments;
  final double medianCtr;
  final int totalVideos;
  final int totalViews;
  final double uploadFrequency; // e.g. 2.3 uploads/week
  final double topOutlierMultiplier; // e.g. 4.2x median
  final double viewsVelocity;
  final String bestVideoLength;
  final List<String> titlePatterns;
  final List<TopicPerformanceMultiplier> topicPerformanceMultipliers;
  final String targetAudienceLevel;
  final List<String> topTopicClusters;
  final String topFormat;
  final String? avatarUrl;
  final String? bannerUrl;
  final bool isLiveConnected;
  final List<ChannelRecentVideo> recentVideos;
  final AudienceInsight audienceInsight;
  final String signatureCreatorStyle;
  final CreatorAuthenticityProfile authenticityProfile;

  const ChannelGraph({
    this.channelId,
    this.channelName = '',
    required this.handle,
    this.channelDescription = '',
    this.niche = '',
    this.subscribers = 0,
    this.medianViews = 0,
    this.averageLikes = 0,
    this.averageComments = 0,
    this.medianCtr = 0.0,
    this.totalVideos = 0,
    this.totalViews = 0,
    this.uploadFrequency = 2.3,
    this.topOutlierMultiplier = 3.8,
    this.viewsVelocity = 5.2,
    this.bestVideoLength = '10–14 min',
    this.titlePatterns = const [
      'Contrarian thesis with benchmark proof',
      'System teardown & lessons learned',
      'Cost & architectural breakdown'
    ],
    this.topicPerformanceMultipliers = const [],
    this.targetAudienceLevel = '',
    this.topTopicClusters = const [],
    this.topFormat = 'Long-Form + Shorts',
    this.avatarUrl,
    this.bannerUrl,
    this.isLiveConnected = false,
    this.recentVideos = const [],
    this.audienceInsight = const AudienceInsight(),
    this.signatureCreatorStyle = '',
    this.authenticityProfile = const CreatorAuthenticityProfile(),
  });

  /// Check if the channel graph contains synced live data
  bool get isConfigured =>
      handle.isNotEmpty && (subscribers > 0 || isLiveConnected);

  /// Formatted upload cadence (e.g. "2.3 / week")
  String get uploadFrequencyFormatted =>
      '${uploadFrequency.toStringAsFixed(1)} / week';

  /// Concrete predicted performance ladder based on live channel median views:
  /// 0.7x, 1.0x, 1.5x, 2.0x
  Map<String, int> get predictedPerformanceLadder {
    final base = medianViews > 0 ? medianViews : 10000;
    return {
      '0.7x': (base * 0.7).round(),
      '1.0x': base,
      '1.5x': (base * 1.5).round(),
      '2.0x': (base * 2.0).round(),
    };
  }

  /// All audience comments extracted across recent videos
  List<ChannelComment> get allRecentComments {
    final list = <ChannelComment>[];
    for (final video in recentVideos) {
      list.addAll(video.topComments);
    }
    return list;
  }

  /// All audience requests specifically mined from comment threads
  List<ChannelComment> get audienceRequests {
    return allRecentComments
        .where((c) =>
            c.intentCategory == ChannelCommentIntent.request ||
            c.intentCategory == ChannelCommentIntent.question)
        .toList();
  }

  ChannelGraph copyWith({
    String? channelId,
    String? channelName,
    String? handle,
    String? channelDescription,
    String? niche,
    int? subscribers,
    int? medianViews,
    int? averageLikes,
    int? averageComments,
    double? medianCtr,
    int? totalVideos,
    int? totalViews,
    double? uploadFrequency,
    double? topOutlierMultiplier,
    double? viewsVelocity,
    String? bestVideoLength,
    List<String>? titlePatterns,
    List<TopicPerformanceMultiplier>? topicPerformanceMultipliers,
    String? targetAudienceLevel,
    List<String>? topTopicClusters,
    String? topFormat,
    String? avatarUrl,
    String? bannerUrl,
    bool? isLiveConnected,
    List<ChannelRecentVideo>? recentVideos,
    AudienceInsight? audienceInsight,
    String? signatureCreatorStyle,
    CreatorAuthenticityProfile? authenticityProfile,
  }) {
    return ChannelGraph(
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      handle: handle ?? this.handle,
      channelDescription: channelDescription ?? this.channelDescription,
      niche: niche ?? this.niche,
      subscribers: subscribers ?? this.subscribers,
      medianViews: medianViews ?? this.medianViews,
      averageLikes: averageLikes ?? this.averageLikes,
      averageComments: averageComments ?? this.averageComments,
      medianCtr: medianCtr ?? this.medianCtr,
      totalVideos: totalVideos ?? this.totalVideos,
      totalViews: totalViews ?? this.totalViews,
      uploadFrequency: uploadFrequency ?? this.uploadFrequency,
      topOutlierMultiplier:
          topOutlierMultiplier ?? this.topOutlierMultiplier,
      viewsVelocity: viewsVelocity ?? this.viewsVelocity,
      bestVideoLength: bestVideoLength ?? this.bestVideoLength,
      titlePatterns: titlePatterns ?? this.titlePatterns,
      topicPerformanceMultipliers:
          topicPerformanceMultipliers ?? this.topicPerformanceMultipliers,
      targetAudienceLevel: targetAudienceLevel ?? this.targetAudienceLevel,
      topTopicClusters: topTopicClusters ?? this.topTopicClusters,
      topFormat: topFormat ?? this.topFormat,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      isLiveConnected: isLiveConnected ?? this.isLiveConnected,
      recentVideos: recentVideos ?? this.recentVideos,
      audienceInsight: audienceInsight ?? this.audienceInsight,
      signatureCreatorStyle:
          signatureCreatorStyle ?? this.signatureCreatorStyle,
      authenticityProfile: authenticityProfile ?? this.authenticityProfile,
    );
  }
}
