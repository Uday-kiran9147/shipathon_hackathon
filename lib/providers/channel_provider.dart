import 'dart:developer';

import 'package:flutter/foundation.dart';
import '../core/services/backend_api_service.dart';
import '../models/channel_graph.dart';

class ChannelProvider extends ChangeNotifier {
  static const String defaultHandle = '@uk';
  final BackendApiService _backendApiService = BackendApiService();
  final Map<String, ChannelGraph> _cachedChannels = {};

  ChannelGraph _channel = const ChannelGraph(handle: defaultHandle);
  bool _isSyncing = false;
  String? _syncError;

  ChannelGraph get channel => _channel;
  bool get isSyncing => _isSyncing;
  String? get syncError => _syncError;
  bool get isConnected => _channel.isConfigured;
  Map<String, ChannelGraph> get cachedChannels =>
      Map.unmodifiable(_cachedChannels);

  // The YouTube & Gemini API keys now live server-side only; the Channel
  // Graph context engine always runs on the Prevue backend, so the app is
  // always "ready" from the client's perspective.
  bool get hasApiKey => true;
  String? get configuredApiKey => null;

  ChannelProvider({String? initialHandle}) {
    if (initialHandle != null && initialHandle.trim().isNotEmpty) {
      final clean = initialHandle.trim().startsWith('@')
          ? initialHandle.trim()
          : '@${initialHandle.trim()}';
      _channel = ChannelGraph(handle: clean);
    }
  }

  /// No-op retained for UI compatibility: API keys are configured on the
  /// backend now, not the client.
  void setApiKey(String? key) {}

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
      final updatedGraph = await _backendApiService.syncChannel(targetHandle);
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
      _syncError = e.toString().replaceAll('Exception: ', '');
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
