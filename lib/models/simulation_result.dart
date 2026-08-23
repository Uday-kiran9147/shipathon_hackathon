import 'daily_blueprint.dart';

enum PerformanceTier {
  topOutlier,     // 🚀 Top 10% Channel Outlier (Est. 3.0×+ Median Views)
  aboveMedian,    // 🟢 Above Median (Est. 1.3×–2.0× Median Views)
  averageBaseline,// 🟡 Average Baseline (Est. 0.8×–1.1× Median Views)
  highFlopRisk,   // 🔴 High Flop Risk (<0.5× Median Views)
}

extension PerformanceTierX on PerformanceTier {
  String get title {
    switch (this) {
      case PerformanceTier.topOutlier:
        return 'Top 10% Channel Outlier';
      case PerformanceTier.aboveMedian:
        return 'Above Channel Median';
      case PerformanceTier.averageBaseline:
        return 'Average Baseline';
      case PerformanceTier.highFlopRisk:
        return 'High Drop-Off Risk';
    }
  }

  String get multiplierLabel {
    switch (this) {
      case PerformanceTier.topOutlier:
        return 'Est. 2.8×–3.5× Median Views';
      case PerformanceTier.aboveMedian:
        return 'Est. 1.4×–2.0× Median Views';
      case PerformanceTier.averageBaseline:
        return 'Est. 0.9×–1.1× Median Views';
      case PerformanceTier.highFlopRisk:
        return 'Est. <0.5× Median Views';
    }
  }
}

enum HazardSeverity {
  critical, // Ruby Red
  warning,  // Amber
  minor,    // Slate
}

class RetentionHazard {
  final int startSeconds;
  final int endSeconds;
  final HazardSeverity severity;
  final int dropOffRiskPercentage;
  final String title;
  final String explanation;
  final String flaggedScriptLine;

  const RetentionHazard({
    required this.startSeconds,
    required this.endSeconds,
    required this.severity,
    required this.dropOffRiskPercentage,
    required this.title,
    required this.explanation,
    required this.flaggedScriptLine,
  });

  String get timestampRange =>
      '0:${startSeconds.toString().padLeft(2, '0')} - 0:${endSeconds.toString().padLeft(2, '0')}';
}

class PrescriptiveFix {
  final String id;
  final String fixType;
  final String description;
  final String originalSnippet;
  final String replacementSnippet;
  final double scoreLift;
  final bool isApplied;

  const PrescriptiveFix({
    required this.id,
    required this.fixType,
    required this.description,
    required this.originalSnippet,
    required this.replacementSnippet,
    required this.scoreLift,
    this.isApplied = false,
  });

  PrescriptiveFix copyWith({
    String? id,
    String? fixType,
    String? description,
    String? originalSnippet,
    String? replacementSnippet,
    double? scoreLift,
    bool? isApplied,
  }) {
    return PrescriptiveFix(
      id: id ?? this.id,
      fixType: fixType ?? this.fixType,
      description: description ?? this.description,
      originalSnippet: originalSnippet ?? this.originalSnippet,
      replacementSnippet: replacementSnippet ?? this.replacementSnippet,
      scoreLift: scoreLift ?? this.scoreLift,
      isApplied: isApplied ?? this.isApplied,
    );
  }
}

class SimulationResult {
  final String id;
  final String title;
  final String draftScript;
  final BlueprintFormat format;
  final double hookScore;
  final double resonanceScore;
  final PerformanceTier performanceTier;
  final List<RetentionHazard> hazards;
  final List<PrescriptiveFix> fixes;
  final DateTime createdAt;

  const SimulationResult({
    required this.id,
    required this.title,
    required this.draftScript,
    required this.format,
    required this.hookScore,
    required this.resonanceScore,
    required this.performanceTier,
    required this.hazards,
    required this.fixes,
    required this.createdAt,
  });

  SimulationResult copyWith({
    String? id,
    String? title,
    String? draftScript,
    BlueprintFormat? format,
    double? hookScore,
    double? resonanceScore,
    PerformanceTier? performanceTier,
    List<RetentionHazard>? hazards,
    List<PrescriptiveFix>? fixes,
    DateTime? createdAt,
  }) {
    return SimulationResult(
      id: id ?? this.id,
      title: title ?? this.title,
      draftScript: draftScript ?? this.draftScript,
      format: format ?? this.format,
      hookScore: hookScore ?? this.hookScore,
      resonanceScore: resonanceScore ?? this.resonanceScore,
      performanceTier: performanceTier ?? this.performanceTier,
      hazards: hazards ?? this.hazards,
      fixes: fixes ?? this.fixes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
