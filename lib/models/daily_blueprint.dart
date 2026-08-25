import 'channel_graph.dart';

enum BlueprintFormat {
  longForm,
  short,
}

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
  final String categoryTag;
  final DateTime date;
  final bool isBookmarked;
  final ChannelComment? audienceCommentSource;
  final String creatorAuthenticityProof;
  final String engagementContext;

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
    required this.categoryTag,
    required this.date,
    this.isBookmarked = false,
    this.audienceCommentSource,
    this.creatorAuthenticityProof = '',
    this.engagementContext = '',
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
    String? categoryTag,
    DateTime? date,
    bool? isBookmarked,
    ChannelComment? audienceCommentSource,
    String? creatorAuthenticityProof,
    String? engagementContext,
  }) {
    return DailyBlueprint(
      id: id ?? this.id,
      title: title ?? this.title,
      format: format ?? this.format,
      formatLabel: formatLabel ?? this.formatLabel,
      hookText: hookText ?? this.hookText,
      thumbnailConceptLeft: thumbnailConceptLeft ?? this.thumbnailConceptLeft,
      thumbnailConceptRight: thumbnailConceptRight ?? this.thumbnailConceptRight,
      thumbnailTag: thumbnailTag ?? this.thumbnailTag,
      dataProofReason: dataProofReason ?? this.dataProofReason,
      predictedMultiplier: predictedMultiplier ?? this.predictedMultiplier,
      categoryTag: categoryTag ?? this.categoryTag,
      date: date ?? this.date,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      audienceCommentSource:
          audienceCommentSource ?? this.audienceCommentSource,
      creatorAuthenticityProof:
          creatorAuthenticityProof ?? this.creatorAuthenticityProof,
      engagementContext: engagementContext ?? this.engagementContext,
    );
  }
}

