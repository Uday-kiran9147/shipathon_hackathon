import 'dart:developer';

import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../core/services/youtube_api_service.dart';
import '../models/channel_graph.dart';

class ChannelProvider extends ChangeNotifier {
  static const String defaultHandle = '@uk';
  final YouTubeApiService _youtubeService = YouTubeApiService();
  final Map<String, ChannelGraph> _cachedChannels = {};

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
  Map<String, ChannelGraph> get cachedChannels =>
      Map.unmodifiable(_cachedChannels);

  ChannelProvider({String? initialHandle}) {
    final envKey = AppConstants.youtubeApiKey;
    if (envKey.isNotEmpty) {
      _configuredApiKey = envKey;
      _youtubeService.configureApiKey(envKey);
    }
    if (initialHandle != null && initialHandle.trim().isNotEmpty) {
      final clean = initialHandle.trim().startsWith('@')
          ? initialHandle.trim()
          : '@${initialHandle.trim()}';
      _channel = ChannelGraph(handle: clean);
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

  /// Switch to another channel handle with cache-first instant loading
  Future<bool> switchChannel(String handle) async {
    final cleanHandle = handle.trim().startsWith('@')
        ? handle.trim()
        : '@${handle.trim()}';

    if (_cachedChannels.containsKey(cleanHandle)) {
      _channel = _cachedChannels[cleanHandle]!;
      _syncError = null;
      notifyListeners();
      return true;
    }

    return syncChannel(cleanHandle);
  }

  /// Sync YouTube Channel live only via handle
  Future<bool> syncChannel([String? handleOrQuery]) async {
    final targetHandle = (handleOrQuery == null || handleOrQuery.trim().isEmpty)
        ? (_channel.handle.isNotEmpty ? _channel.handle : defaultHandle)
        : (handleOrQuery.trim().startsWith('@')
              ? handleOrQuery.trim()
              : '@${handleOrQuery.trim()}');

    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    try {
      final updatedGraph = await _youtubeService.fetchChannelByHandle(
        targetHandle,
      );
      _channel = updatedGraph;
      _cachedChannels[targetHandle] = updatedGraph;
      _isSyncing = false;
      log(
        '[ChannelProvider] Synced channel $targetHandle: ${updatedGraph.channelName}',
      );

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
    _cachedChannels[updated.handle] = updated;
    notifyListeners();
  }

  void resetToDefault() {
    _channel = const ChannelGraph(handle: defaultHandle);
    _syncError = null;
    notifyListeners();
  }
}
