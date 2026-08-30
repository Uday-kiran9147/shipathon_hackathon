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
}
