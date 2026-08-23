import 'package:flutter/foundation.dart';
import '../core/services/blueprint_generator_service.dart';
import '../models/channel_graph.dart';
import '../models/daily_blueprint.dart';

enum BriefingFilter {
  all,
  longForm,
  short,
  saved,
}

class BriefingProvider extends ChangeNotifier {
  final BlueprintGeneratorService _generatorService =
      BlueprintGeneratorService();

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

  /// Sync blueprints to match the new ChannelGraph profile
  void updateForChannel(ChannelGraph channel) {
    _blueprints = _generatorService.generateBlueprintsForChannel(channel);
    notifyListeners();
  }

  /// Pull-to-refresh
  Future<void> refreshBriefing(ChannelGraph channel) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 650));
    _blueprints = _generatorService.generateBlueprintsForChannel(channel);
    _isLoading = false;
    notifyListeners();
  }

  /// AI Generates a brand-new blueprint in real time
  Future<DailyBlueprint> generateFreshBlueprint(ChannelGraph channel) async {
    _isGeneratingFresh = true;
    notifyListeners();

    try {
      final newBlueprint =
          await _generatorService.generateFreshBlueprintOnDemand(channel);
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
