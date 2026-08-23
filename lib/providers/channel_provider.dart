import 'dart:developer';

import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../core/services/youtube_api_service.dart';
import '../models/channel_graph.dart';

class ChannelProvider extends ChangeNotifier {
  static const String defaultHandle = '@Srimankotaru';
  final YouTubeApiService _youtubeService = YouTubeApiService();

  ChannelGraph _channel = const ChannelGraph(handle: defaultHandle);
  bool _isSyncing = false;
  String? _syncError;
  String? _configuredApiKey;

  ChannelGraph get channel => _channel;
  bool get isSyncing => _isSyncing;
  String? get syncError => _syncError;
  String? get configuredApiKey => _configuredApiKey;
  bool get hasApiKey => _youtubeService.hasApiKey;
  bool get isConnected => _channel.isConfigured;

  ChannelProvider() {
    final envKey = AppConstants.youtubeApiKey;
    if (envKey.isNotEmpty) {
      _configuredApiKey = envKey;
      _youtubeService.configureApiKey(envKey);
      syncChannel(defaultHandle);
    }
  }

  /// Set user's custom YouTube API Key and auto-sync default channel
  void setApiKey(String? key) {
    _configuredApiKey = key;
    _youtubeService.configureApiKey(key);
    if (key != null && key.isNotEmpty && !_channel.isConfigured) {
      syncChannel(_channel.handle.isNotEmpty ? _channel.handle : defaultHandle);
    }
    notifyListeners();
  }

  /// Sync YouTube Channel live only via handle
  Future<bool> syncChannel([String? handleOrQuery]) async {
    final targetHandle = (handleOrQuery == null || handleOrQuery.trim().isEmpty)
        ? (_channel.handle.isNotEmpty ? _channel.handle : defaultHandle)
        : handleOrQuery.trim();

    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    try {
      final updatedGraph = await _youtubeService.fetchChannelByHandle(
        targetHandle,
      );
      _channel = updatedGraph;
      _isSyncing = false;
      // log proven topic clusters
      log('[ChannelProvider] Initialized with API Key. Default channel: ${channel.topTopicClusters.map((c) => c.toString()).join(', ')}');
   
      notifyListeners();
      return true;
    } catch (e) {
      _isSyncing = false;
      _syncError = e.toString().replaceAll('YouTubeApiException: ', '');
      notifyListeners();
      return false;
    }
  }

  void updateChannel(ChannelGraph updated) {
    _channel = updated;
    notifyListeners();
  }

  void resetToDefault() {
    _channel = const ChannelGraph(handle: defaultHandle);
    _syncError = null;
    notifyListeners();
  }
}
