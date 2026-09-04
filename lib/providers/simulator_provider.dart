import 'package:flutter/foundation.dart';
import '../core/services/backend_api_service.dart';
import '../core/services/simulator_engine_service.dart';
import '../models/channel_graph.dart';
import '../models/daily_blueprint.dart';
import '../models/simulation_result.dart';
import 'subscription_provider.dart';

class SimulatorProvider extends ChangeNotifier {
  final SimulatorEngineService _engineService = SimulatorEngineService();
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
      // 1. Attempt backend simulation with PostgreSQL limit enforcement
      final backendResponse = await _backendApiService.runSimulationOnBackend(
        title: _titleInput,
        draftScript: _scriptInput,
        format: _selectedFormat,
        channel: channel,
      );

      if (backendResponse != null && subscriptionProvider != null) {
        if (backendResponse['simulationsUsedThisMonth'] != null) {
          subscriptionProvider.updateSimulationUsage(
            simulationsUsedThisMonth:
                backendResponse['simulationsUsedThisMonth'] as int,
            freeSimulationsLimit:
                backendResponse['freeSimulationsLimit'] as int?,
            isPro: backendResponse['isPro'] as bool?,
          );
        }
      }

      // 2. Compute full client-side metrics and hazards
      final result = await _engineService.runSimulation(
        title: _titleInput,
        draftScript: _scriptInput,
        format: _selectedFormat,
        channel: channel,
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

    // Update simulation result scores
    final updated = _engineService.applyPrescriptiveFix(
      currentResult: _currentResult!,
      fixId: fixId,
    );

    _currentResult = updated;
    notifyListeners();
  }

  void reset() {
    _currentResult = null;
    notifyListeners();
  }
}
