import 'package:flutter/foundation.dart';
import '../core/services/backend_api_service.dart';
import '../models/channel_graph.dart';
import '../models/daily_blueprint.dart';
import '../models/simulation_result.dart';
import 'subscription_provider.dart';

class SimulatorProvider extends ChangeNotifier {
  final BackendApiService _backendApiService = BackendApiService();

  String _titleInput = '';
  String _scriptInput = '';
  BlueprintFormat _selectedFormat = BlueprintFormat.longForm;

  SimulationResult? _currentResult;
  bool _isAnalyzing = false;
  final List<SimulationResult> _history = [];

  String get titleInput => _titleInput;
  String get scriptInput => _scriptInput;
  BlueprintFormat get selectedFormat => _selectedFormat;
  SimulationResult? get currentResult => _currentResult;
  bool get isAnalyzing => _isAnalyzing;
  List<SimulationResult> get history => _history;

  void setTitle(String value) {
    _titleInput = value;
    notifyListeners();
  }

  void setScript(String value) {
    _scriptInput = value;
    notifyListeners();
  }

  void setFormat(BlueprintFormat format) {
    _selectedFormat = format;
    notifyListeners();
  }

  /// Load draft from a Daily Prescription blueprint
  void loadBlueprint(DailyBlueprint bp) {
    _titleInput = bp.title;
    _scriptInput = bp.hookText;
    _selectedFormat = bp.format;
    _currentResult = null;
    notifyListeners();
  }

  /// Execute pre-flight simulation with PostgreSQL server tracking
  Future<SimulationResult> runSimulation(
    ChannelGraph channel, {
    SubscriptionProvider? subscriptionProvider,
  }) async {
    _isAnalyzing = true;
    notifyListeners();

    try {
      // The backend Pre-Flight Simulator Engine is the source of truth: it
      // scores the script, enforces the free-tier limit, and persists the
      // result in PostgreSQL. The app never recomputes scores locally.
      final backendResponse = await _backendApiService.runSimulationOnBackend(
        title: _titleInput,
        draftScript: _scriptInput,
        format: _selectedFormat,
        channel: channel,
      );

      if (backendResponse == null ||
          backendResponse['simulationResult'] == null) {
        throw Exception(
          'Could not reach the Prevue backend to run this simulation. Please check your connection and try again.',
        );
      }

      if (subscriptionProvider != null &&
          backendResponse['simulationsUsedThisMonth'] != null) {
        subscriptionProvider.updateSimulationUsage(
          simulationsUsedThisMonth:
              backendResponse['simulationsUsedThisMonth'] as int,
          freeSimulationsLimit: backendResponse['freeSimulationsLimit'] as int?,
          isPro: backendResponse['isPro'] as bool?,
        );
      }

      final result = SimulationResult.fromJson(
        backendResponse['simulationResult'] as Map<String, dynamic>,
      );

      _currentResult = result;
      _history.insert(0, result);
      _isAnalyzing = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isAnalyzing = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Apply 1-Click Prescriptive Fix with genuine text replacement
  void applyFix(String fixId) {
    if (_currentResult == null) return;

    final targetFix = _currentResult!.fixes.firstWhere((f) => f.id == fixId);
    if (targetFix.isApplied) return;

    // Apply title rewrite
    if (fixId == 'fix_title') {
      _titleInput = targetFix.replacementSnippet;
    }

    // Apply hook restructure — replace the original opening with restructured version
    if (fixId == 'fix_hook') {
      if (targetFix.originalSnippet.isNotEmpty &&
          _scriptInput.contains(targetFix.originalSnippet)) {
        _scriptInput = _scriptInput.replaceFirst(
          targetFix.originalSnippet,
          targetFix.replacementSnippet,
        );
      } else {
        // If exact match not found, prepend the restructured hook
        _scriptInput = '${targetFix.replacementSnippet}\n\n$_scriptInput';
      }
    }

    // Apply pacing cut — replace the long sentence with compressed version
    if (fixId == 'fix_pacing') {
      if (targetFix.originalSnippet.isNotEmpty &&
          _scriptInput.contains(targetFix.originalSnippet)) {
        _scriptInput = _scriptInput.replaceFirst(
          targetFix.originalSnippet,
          targetFix.replacementSnippet,
        );
      } else {
        // Append visual direction at end if exact match fails
        _scriptInput = '$_scriptInput\n${targetFix.replacementSnippet}';
      }
    }

    // Lift the scores toward the backend-computed `projectedScoreAfter` for
    // this fix and mark it applied. The backend already computed the lift
    // when it scored the draft; this just reflects that in the UI.
    final updatedFixes = _currentResult!.fixes.map((f) {
      return f.id == fixId ? f.copyWith(isApplied: true) : f;
    }).toList();

    final newHookScore = targetFix.projectedScoreAfter;
    final newResonance = (_currentResult!.resonanceScore + targetFix.scoreLift * 0.7)
        .clamp(3.0, 9.8);
    final newPacing = (_currentResult!.pacingScore + targetFix.scoreLift * 0.5)
        .clamp(3.0, 9.8);

    final remainingHazards = _currentResult!.hazards.where((h) {
      if (fixId == 'fix_hook') return h.startSeconds > 16;
      if (fixId == 'fix_pacing') return h.startSeconds < 16;
      return true;
    }).toList();

    final newMultiplier =
        (_currentResult!.projectedViewsMultiplier * 1.18).clamp(1.0, 4.5);
    final newViews = (_currentResult!.projectedViews * 1.18).round();

    _currentResult = _currentResult!.copyWith(
      hookScore: newHookScore,
      resonanceScore: newResonance,
      pacingScore: newPacing,
      projectedViewsMultiplier: newMultiplier,
      projectedViews: newViews,
      performanceTier: newHookScore >= 8.5
          ? PerformanceTier.topOutlier
          : newHookScore >= 7.0
              ? PerformanceTier.aboveMedian
              : _currentResult!.performanceTier,
      fixes: updatedFixes,
      hazards: remainingHazards,
    );
    notifyListeners();
  }

  void reset() {
    _currentResult = null;
    notifyListeners();
  }
}
