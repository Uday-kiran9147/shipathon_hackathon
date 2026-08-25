import '../network/dio_client.dart';
import '../../models/channel_graph.dart';

/// YouTube Data API v3 Service via Dio Helper
class YouTubeApiService {
  static final YouTubeApiService _instance = YouTubeApiService._internal();
  factory YouTubeApiService() => _instance;
  YouTubeApiService._internal();

  final DioClient _dioClient = DioClient();

  /// Set the active YouTube API Key
  void configureApiKey(String? key) {
    _dioClient.setApiKey(key);
  }

  String? get currentApiKey => _dioClient.apiKey;
  bool get hasApiKey =>
      _dioClient.apiKey != null && _dioClient.apiKey!.isNotEmpty;

  /// Fetch live channel data by handle (e.g. "@Telusko", "@RevenueCat", etc.)
  Future<ChannelGraph> fetchChannelByHandle(String handleInput) async {
    final cleanHandle = handleInput.trim().startsWith('@')
        ? handleInput.trim()
        : '@${handleInput.trim()}';

    if (cleanHandle.length <= 1) {
      throw const YouTubeApiException(
        message: 'Please enter a valid YouTube channel handle (e.g. @RevenueCat)',
      );
    }

    if (!hasApiKey) {
      throw const YouTubeApiException(
        message:
            'YouTube API Key not configured. Please add your YouTube Data API v3 key in settings or .env to fetch live channel data.',
      );
    }

    // Call YouTube Data API v3
    final response = await _dioClient.get(
      'channels',
      queryParameters: {
        'part': 'snippet,statistics,contentDetails,topicDetails',
        'forHandle': cleanHandle,
      },
    );

    final items = response.data['items'] as List<dynamic>?;
    if (items != null && items.isNotEmpty) {
      final channelItem = items.first as Map<String, dynamic>;
      return await _parseLiveChannelItem(channelItem, cleanHandle);
    }

    throw YouTubeApiException(
      message: 'No YouTube channel found with handle "$cleanHandle".',
      statusCode: 404,
    );
  }

  /// Fetch live channel data by channelId (e.g. "UC...")
  Future<ChannelGraph> fetchChannelById(String channelId) async {
    if (!hasApiKey) {
      throw const YouTubeApiException(
        message:
            'YouTube API Key not configured. Please add your YouTube Data API v3 key in settings or .env to fetch live channel data.',
      );
    }

    final response = await _dioClient.get(
      'channels',
      queryParameters: {
        'part': 'snippet,statistics,contentDetails,topicDetails',
        'id': channelId,
      },
    );

    final items = response.data['items'] as List<dynamic>?;
    if (items != null && items.isNotEmpty) {
      final channelItem = items.first as Map<String, dynamic>;
      final customUrl =
          channelItem['snippet']?['customUrl'] as String? ?? '@channel';
      return await _parseLiveChannelItem(channelItem, customUrl);
    }

    throw YouTubeApiException(
      message: 'Channel ID "$channelId" could not be found on YouTube.',
      statusCode: 404,
    );
  }

  /// Parse live YouTube Data API JSON structure
  Future<ChannelGraph> _parseLiveChannelItem(
    Map<String, dynamic> item,
    String handle,
  ) async {
    final snippet = item['snippet'] as Map<String, dynamic>? ?? {};
    final statistics = item['statistics'] as Map<String, dynamic>? ?? {};
    final contentDetails =
        item['contentDetails'] as Map<String, dynamic>? ?? {};
    final topicDetails = item['topicDetails'] as Map<String, dynamic>? ?? {};

    final channelId = item['id'] as String? ?? '';
    final channelTitle = snippet['title'] as String? ?? 'YouTube Creator';
    final customUrl = snippet['customUrl'] as String? ?? handle;
    final avatarUrl = snippet['thumbnails']?['high']?['url'] as String? ??
        snippet['thumbnails']?['medium']?['url'] as String? ??
        snippet['thumbnails']?['default']?['url'] as String?;

    final subCount =
        int.tryParse(statistics['subscriberCount']?.toString() ?? '0') ?? 0;
    final totalVideos =
        int.tryParse(statistics['videoCount']?.toString() ?? '0') ?? 0;
    final totalViews =
        int.tryParse(statistics['viewCount']?.toString() ?? '0') ?? 0;

    // Collect all video data from live uploads
    List<ChannelRecentVideo> recentVideos = [];
    final allTags = <String>[];
    final allVideoTitles = <String>[];

    int calculatedMedianViews =
        (totalVideos > 0 && totalViews > 0) ? (totalViews ~/ totalVideos) : 0;

    final uploadsPlaylistId =
        contentDetails['relatedPlaylists']?['uploads'] as String?;

    if (uploadsPlaylistId != null && uploadsPlaylistId.isNotEmpty) {
      try {
        final playlistResponse = await _dioClient.get(
          'playlistItems',
          queryParameters: {
            'part': 'snippet,contentDetails',
            'playlistId': uploadsPlaylistId,
            'maxResults': 6,
          },
        );

        final playlistItems = playlistResponse.data['items'] as List<dynamic>?;
        if (playlistItems != null && playlistItems.isNotEmpty) {
          final videoIds = playlistItems
              .map((p) => p['contentDetails']?['videoId'] as String?)
              .whereType<String>()
              .join(',');

          if (videoIds.isNotEmpty) {
            final videosResponse = await _dioClient.get(
              'videos',
              queryParameters: {
                'part': 'snippet,statistics',
                'id': videoIds,
              },
            );

            final videoItems = videosResponse.data['items'] as List<dynamic>?;
            if (videoItems != null) {
              final viewsList = <int>[];
              for (final v in videoItems) {
                final vSnippet = v['snippet'] as Map<String, dynamic>? ?? {};
                final vStats = v['statistics'] as Map<String, dynamic>? ?? {};
                final vTitle = vSnippet['title'] as String? ?? '';
                final vTags = (vSnippet['tags'] as List<dynamic>?)
                        ?.map((t) => t.toString())
                        .toList() ??
                    [];

                if (vTitle.isNotEmpty) allVideoTitles.add(vTitle);
                allTags.addAll(vTags);

                final vViews =
                    int.tryParse(vStats['viewCount']?.toString() ?? '0') ?? 0;
                if (vViews > 0) {
                  viewsList.add(vViews);
                }

                recentVideos.add(
                  ChannelRecentVideo(
                    id: v['id'] as String? ?? '',
                    title: vTitle.isNotEmpty ? vTitle : 'Untitled',
                    views: vViews,
                    publishedAt: DateTime.tryParse(
                            vSnippet['publishedAt']?.toString() ?? '') ??
                        DateTime.now(),
                    thumbnailUrl: vSnippet['thumbnails']?['medium']?['url']
                        as String?,
                  ),
                );
              }

              if (viewsList.isNotEmpty) {
                viewsList.sort();
                calculatedMedianViews = viewsList[viewsList.length ~/ 2];
              }
            }
          }
        }
      } catch (_) {
        // Silent catch for playlist sub-query
      }
    }

    // Extract Wikipedia Topic Categories directly from YouTube API response
    final topicCategories = (topicDetails['topicCategories'] as List<dynamic>?)
            ?.map((u) => u
                .toString()
                .split('/')
                .last
                .replaceAll('_', ' ')
                .replaceAll('(sociology)', '')
                .replaceAll('(genre)', '')
                .trim())
            .where((t) => t.isNotEmpty)
            .toList() ??
        [];

    // Extract dynamic topic clusters directly from live tags, titles, and topic categories
    final topicClusters = _extractDynamicTopicClusters(
      channelTitle: channelTitle,
      allTags: allTags,
      allVideoTitles: allVideoTitles,
      topicCategories: topicCategories,
    );

    // Synthesize niche directly from live topic categories & top tags
    final niche = _synthesizeDynamicNiche(
      topicCategories: topicCategories,
      topicClusters: topicClusters,
      channelTitle: channelTitle,
    );

    return ChannelGraph(
      channelId: channelId,
      channelName: channelTitle,
      handle: customUrl.startsWith('@') ? customUrl : '@$customUrl',
      niche: niche,
      subscribers: subCount,
      medianViews: calculatedMedianViews,
      medianCtr: 5.6,
      totalVideos: totalVideos,
      targetAudienceLevel: 'Core Channel Community',
      topTopicClusters: topicClusters,
      topFormat: 'Long-Form + Shorts',
      avatarUrl: avatarUrl,
      isLiveConnected: true,
      recentVideos: recentVideos,
    );
  }

  /// Capitalize a tag into a clean title case
  String _capitalizeTag(String text) {
    return text.split(' ').map((w) {
      if (w.isEmpty) return '';
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

  /// Extract clean keyphrases from raw video title
  List<String> _extractTitlePhrases(String title) {
    final phrases = <String>[];
    final parts = title
        .replaceAll(RegExp(r'#\w+'), '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .split(RegExp(r'[|:?]'))
        .map((p) => p.trim())
        .where((p) => p.length > 4)
        .toList();

    for (final part in parts) {
      if (!part.toLowerCase().contains('http') && !part.toLowerCase().contains('instagram')) {
        phrases.add(part);
      }
    }
    return phrases;
  }

  /// Dynamically mine topic clusters PURELY from live API video tags, titles, and topic categories
  List<String> _extractDynamicTopicClusters({
    required String channelTitle,
    required List<String> allTags,
    required List<String> allVideoTitles,
    required List<String> topicCategories,
  }) {
    final titleWords =
        channelTitle.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();

    final resultClusters = <String>{};

    // 1. Add Wikipedia Topic Categories from YouTube API
    for (final topic in topicCategories) {
      if (topic.length > 2) {
        resultClusters.add(_capitalizeTag(topic));
      }
    }

    // 2. Add high-value distinct tags from YouTube API video metadata
    final tagFrequency = <String, int>{};
    for (final rawTag in allTags) {
      final tag = rawTag.trim().toLowerCase();
      if (tag.length < 3) continue;

      // Filter out creator name tags
      final isCreatorName = titleWords.any((tw) => tag.contains(tw));
      if (isCreatorName) continue;

      // Filter out generic stop words
      if (tag == 'india' || tag == 'hindi' || tag == 'telugu' || tag == 'tamil' || tag == 'desi' || tag == 'fun' || tag == 'friends') {
        continue;
      }

      tagFrequency[tag] = (tagFrequency[tag] ?? 0) + 1;
    }

    final sortedTags = tagFrequency.keys.toList()
      ..sort((a, b) => tagFrequency[b]!.compareTo(tagFrequency[a]!));

    for (final tag in sortedTags.take(4)) {
      resultClusters.add(_capitalizeTag(tag));
    }

    // 3. Add distinctive keyphrases from live video titles if clusters < 4
    for (final title in allVideoTitles) {
      if (resultClusters.length >= 4) break;
      final phrases = _extractTitlePhrases(title);
      for (final p in phrases) {
        if (resultClusters.length >= 4) break;
        if (p.length < 35) {
          resultClusters.add(p);
        }
      }
    }

    // If result is empty, use primary channel title
    if (resultClusters.isEmpty) {
      resultClusters.add('$channelTitle Core Content');
    }

    return resultClusters.take(4).toList();
  }

  /// Synthesize niche dynamically from live topic categories & mined clusters
  String _synthesizeDynamicNiche({
    required List<String> topicCategories,
    required List<String> topicClusters,
    required String channelTitle,
  }) {
    if (topicCategories.isNotEmpty && topicClusters.isNotEmpty) {
      final primaryCategory = _capitalizeTag(topicCategories.first);
      final primaryCluster = topicClusters.first;
      if (!primaryCategory.toLowerCase().contains(primaryCluster.toLowerCase())) {
        return '$primaryCategory & $primaryCluster';
      }
      return primaryCategory;
    }

    if (topicClusters.isNotEmpty) {
      if (topicClusters.length > 1) {
        return '${topicClusters[0]} & ${topicClusters[1]}';
      }
      return topicClusters[0];
    }

    return '$channelTitle Content';
  }
}
