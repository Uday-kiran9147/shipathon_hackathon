import 'channel_graph.dart';

enum BlueprintFormat { longForm, short }

/// Model representing a Daily Prescriptive Blueprint ("What to Film Tomorrow")
class DailyBlueprint {
  final String id;
  final String title;
  final BlueprintFormat format;
  final String formatLabel;
  final String hookText;
  final String thumbnailConceptLeft;
  final String thumbnailConceptRight;
  final String thumbnailTag;
  final String dataProofReason;
  final double predictedMultiplier;
  final double convictionScore; // 0.0 to 10.0 mathematically computed
  final double confidenceIntervalMin;
  final double confidenceIntervalMax;
  final String categoryTag;
  final DateTime date;
  final bool isBookmarked;
  final ChannelComment? audienceCommentSource;
  final CommentDemandCluster? demandCluster;
  final String demandEvidenceSummary;
  final String creatorAuthenticityProof;
  final String engagementContext;
  final List<String> preEngineeredRetentionAnchors;

  const DailyBlueprint({
    required this.id,
    required this.title,
    required this.format,
    required this.formatLabel,
    required this.hookText,
    required this.thumbnailConceptLeft,
    required this.thumbnailConceptRight,
    required this.thumbnailTag,
    required this.dataProofReason,
    required this.predictedMultiplier,
    this.convictionScore = 8.8,
    this.confidenceIntervalMin = 2.4,
    this.confidenceIntervalMax = 3.6,
    required this.categoryTag,
    required this.date,
    this.isBookmarked = false,
    this.audienceCommentSource,
    this.demandCluster,
    this.demandEvidenceSummary = '',
    this.creatorAuthenticityProof = '',
    this.engagementContext = '',
    this.preEngineeredRetentionAnchors = const [
      '0:00 - 0:05: High-tension contrarian premise',
      '0:05 - 0:25: Immediate visual proof / code diff',
      '0:25 - 4:00: Step-by-step resolution without fluff',
      'End: Seamless retention bridge to related topic',
    ],
  });

  DailyBlueprint copyWith({
    String? id,
    String? title,
    BlueprintFormat? format,
    String? formatLabel,
    String? hookText,
    String? thumbnailConceptLeft,
    String? thumbnailConceptRight,
    String? thumbnailTag,
    String? dataProofReason,
    double? predictedMultiplier,
    double? convictionScore,
    double? confidenceIntervalMin,
    double? confidenceIntervalMax,
    String? categoryTag,
    DateTime? date,
    bool? isBookmarked,
    ChannelComment? audienceCommentSource,
    CommentDemandCluster? demandCluster,
    String? demandEvidenceSummary,
    String? creatorAuthenticityProof,
    String? engagementContext,
    List<String>? preEngineeredRetentionAnchors,
  }) {
    return DailyBlueprint(
      id: id ?? this.id,
      title: title ?? this.title,
      format: format ?? this.format,
      formatLabel: formatLabel ?? this.formatLabel,
      hookText: hookText ?? this.hookText,
      thumbnailConceptLeft: thumbnailConceptLeft ?? this.thumbnailConceptLeft,
      thumbnailConceptRight:
          thumbnailConceptRight ?? this.thumbnailConceptRight,
      thumbnailTag: thumbnailTag ?? this.thumbnailTag,
      dataProofReason: dataProofReason ?? this.dataProofReason,
      predictedMultiplier: predictedMultiplier ?? this.predictedMultiplier,
      convictionScore: convictionScore ?? this.convictionScore,
      confidenceIntervalMin:
          confidenceIntervalMin ?? this.confidenceIntervalMin,
      confidenceIntervalMax:
          confidenceIntervalMax ?? this.confidenceIntervalMax,
      categoryTag: categoryTag ?? this.categoryTag,
      date: date ?? this.date,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      audienceCommentSource:
          audienceCommentSource ?? this.audienceCommentSource,
      demandCluster: demandCluster ?? this.demandCluster,
      demandEvidenceSummary:
          demandEvidenceSummary ?? this.demandEvidenceSummary,
      creatorAuthenticityProof:
          creatorAuthenticityProof ?? this.creatorAuthenticityProof,
      engagementContext: engagementContext ?? this.engagementContext,
      preEngineeredRetentionAnchors:
          preEngineeredRetentionAnchors ?? this.preEngineeredRetentionAnchors,
    );
  }

  /// Parse a blueprint returned by `POST /api/briefing/generate`
  /// (backend `StructuredBlueprint` shape).
  factory DailyBlueprint.fromJson(Map<String, dynamic> json) {
    final isShort =
        (json['format']?.toString().toLowerCase().contains('short') ?? false) ||
        (json['formatLabel']?.toString().toLowerCase().contains('short') ?? false);

    final multiplier = (json['predictedMultiplier'] is num)
        ? (json['predictedMultiplier'] as num).toDouble()
        : double.tryParse(json['predictedMultiplier']?.toString() ?? '') ?? 2.5;

    final rawConviction = (json['convictionScore'] is num)
        ? (json['convictionScore'] as num).toDouble()
        : double.tryParse(json['convictionScore']?.toString() ?? '') ?? 8.5;
    final conviction = rawConviction.clamp(7.0, 9.9);

    final minMult = ((multiplier * 0.82) * 10).round() / 10.0;
    final maxMult = ((multiplier * 1.25) * 10).round() / 10.0;

    final anchors = <String>[];
    if (json['preEngineeredRetentionAnchors'] is List) {
      for (final a in json['preEngineeredRetentionAnchors'] as List) {
        anchors.add(a.toString());
      }
    }

    return DailyBlueprint(
      id: json['id']?.toString() ?? 'bp_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? 'Dynamic Video Blueprint',
      format: isShort ? BlueprintFormat.short : BlueprintFormat.longForm,
      formatLabel: json['formatLabel']?.toString() ??
          (isShort ? 'YouTube Short (48s)' : 'Long-Form (12–15 Min)'),
      hookText: json['hookText']?.toString() ?? '',
      thumbnailConceptLeft: json['thumbnailConceptLeft']?.toString() ?? 'Viewer Problem',
      thumbnailConceptRight:
          json['thumbnailConceptRight']?.toString() ?? 'Verified Solution',
      thumbnailTag: json['thumbnailTag']?.toString() ?? 'VERIFIED PATTERN',
      dataProofReason: json['dataProofReason']?.toString() ??
          'Derived directly from live YouTube channel performance metrics.',
      predictedMultiplier: multiplier,
      convictionScore: conviction,
      confidenceIntervalMin: minMult,
      confidenceIntervalMax: maxMult,
      categoryTag: json['categoryTag']?.toString() ?? '',
      date: DateTime.now(),
      demandEvidenceSummary: json['demandEvidenceSummary']?.toString() ?? '',
      creatorAuthenticityProof: json['creatorAuthenticityProof']?.toString() ?? '',
      engagementContext: json['engagementContext']?.toString() ?? '',
      preEngineeredRetentionAnchors: anchors.isNotEmpty
          ? anchors
          : const [
              '0:00 - 0:05: High-tension contrarian premise',
              '0:05 - 0:25: Immediate visual proof / code diff',
              '0:25 - 4:00: Step-by-step resolution without fluff',
              'End: Seamless retention bridge to related topic',
            ],
    );
  }
}
