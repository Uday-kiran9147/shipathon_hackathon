import 'package:flutter/foundation.dart';
import '../core/services/backend_api_service.dart';
import '../models/channel_graph.dart';
import '../models/daily_blueprint.dart';

enum BriefingFilter { all, longForm, short, saved }

class BriefingProvider extends ChangeNotifier {
  final BackendApiService _backendApiService = BackendApiService();

  List<DailyBlueprint> _blueprints = [];
  BriefingFilter _currentFilter = BriefingFilter.all;
  bool _isLoading = false;
  bool _isGeneratingFresh = false;

  BriefingProvider() {
    _blueprints = [];
  }

  List<DailyBlueprint> get blueprints {
    switch (_currentFilter) {
      case BriefingFilter.all:
        return _blueprints;
      case BriefingFilter.longForm:
        return _blueprints
            .where((b) => b.format == BlueprintFormat.longForm)
            .toList();
      case BriefingFilter.short:
        return _blueprints
            .where((b) => b.format == BlueprintFormat.short)
            .toList();
      case BriefingFilter.saved:
        return _blueprints.where((b) => b.isBookmarked).toList();
    }
  }

  BriefingFilter get currentFilter => _currentFilter;
  bool get isLoading => _isLoading;
  bool get isGeneratingFresh => _isGeneratingFresh;

  int get savedCount => _blueprints.where((b) => b.isBookmarked).length;

  void setFilter(BriefingFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  void toggleBookmark(String id) {
    _blueprints = _blueprints.map((bp) {
      if (bp.id == id) {
        return bp.copyWith(isBookmarked: !bp.isBookmarked);
      }
      return bp;
    }).toList();
    notifyListeners();
  }

  /// Sync blueprints to match the new ChannelGraph profile (Instant dynamic catalog synthesis)
  Future<void> updateForChannel(ChannelGraph channel) async {
    if (!channel.isConfigured || channel.recentVideos.isEmpty) {
      _blueprints = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _blueprints = await _backendApiService.generateBriefing(channel);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Explicitly clear all active blueprints
  void clearBlueprints() {
    _blueprints = [];
    notifyListeners();
  }

  /// Loads the most recently generated & persisted briefing for this channel
  /// from `/api/briefing/history`. This never calls Gemini — it only reads
  /// back a batch this account already generated (in this session or a past
  /// one), so a channel's briefing survives app restarts without requiring
  /// another tap of "Generate Daily Briefing".
  Future<void> loadPersistedBriefing(ChannelGraph channel) async {
    if (!channel.isConfigured) {
      _blueprints = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final history = await _backendApiService.getBriefingHistory();
      final match = history.firstWhere(
        (record) =>
            (record['channel_handle']?.toString().toLowerCase() ?? '') ==
            channel.handle.toLowerCase(),
        orElse: () => const {},
      );

      final rawBlueprints = match['blueprints'] as List<dynamic>? ?? [];
      _blueprints = rawBlueprints
          .whereType<Map<String, dynamic>>()
          .map((b) => DailyBlueprint.fromJson(b))
          .toList();
    } catch (e) {
      debugPrint('[BriefingProvider] Could not load persisted briefing: $e');
      _blueprints = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Pull-to-refresh (Refreshes dynamic catalog blueprints)
  Future<void> refreshBriefing(ChannelGraph channel) async {
    if (!channel.isConfigured || channel.recentVideos.isEmpty) {
      _blueprints = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _blueprints = await _backendApiService.generateBriefing(channel);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// AI Generates a brand-new blueprint in real time (via the backend engine)
  Future<DailyBlueprint> generateFreshBlueprint(ChannelGraph channel) async {
    _isGeneratingFresh = true;
    notifyListeners();

    try {
      final fresh = await _backendApiService.generateBriefing(channel);
      if (fresh.isEmpty) {
        throw Exception('Backend returned no fresh blueprint.');
      }
      final newBlueprint = fresh.first;
      _blueprints.insert(0, newBlueprint);
      _isGeneratingFresh = false;
      notifyListeners();
      return newBlueprint;
    } catch (e) {
      _isGeneratingFresh = false;
      notifyListeners();
      rethrow;
    }
  }
}
