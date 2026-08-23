import 'dart:math';
import '../../models/channel_graph.dart';
import '../../models/daily_blueprint.dart';
import '../../models/simulation_result.dart';

/// Pre-Flight Simulator Engine with genuine script analysis and meaningful rewrites
class SimulatorEngineService {
  static final SimulatorEngineService _instance =
      SimulatorEngineService._internal();
  factory SimulatorEngineService() => _instance;
  SimulatorEngineService._internal();

  /// Split script into clean sentences
  List<String> _splitSentences(String text) {
    return text
        .split(RegExp(r'(?<=[.!?\n])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Count words in a string
  int _wordCount(String text) {
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  /// Find the sentence with the highest "tension" signal (numbers, contrarian words, shortest punchy claim)
  int _findHighTensionIndex(List<String> sentences) {
    if (sentences.length <= 1) return 0;

    final tensionSignals = [
      'never', 'stop', 'mistake', 'wrong', 'truth', 'real', 'actually',
      'secret', 'hidden', 'nobody', 'worst', 'cost', 'fail', 'trap',
      'dead', 'broke', 'destroyed', 'shocking', 'insane', 'crazy',
    ];

    int bestIdx = 0;
    double bestScore = -1;

    for (int i = 0; i < sentences.length; i++) {
      final s = sentences[i].toLowerCase();
      double score = 0;

      // Numbers/metrics boost
      if (RegExp(r'\d').hasMatch(s)) score += 3.0;
      if (s.contains('₹') || s.contains('\$') || s.contains('%')) score += 2.0;

      // Tension words boost
      for (final tw in tensionSignals) {
        if (s.contains(tw)) score += 1.5;
      }

      // Question format boost
      if (s.contains('?')) score += 2.0;

      // Short punchy sentence boost (under 15 words)
      final wc = _wordCount(sentences[i]);
      if (wc <= 15 && wc >= 4) score += 1.5;

      // Penalize generic openers
      if (s.startsWith('today') ||
          s.startsWith('in this') ||
          s.startsWith('so ') ||
          s.startsWith('hey') ||
          s.startsWith('welcome')) {
        score -= 4.0;
      }

      if (score > bestScore) {
        bestScore = score;
        bestIdx = i;
      }
    }

    return bestIdx;
  }

  /// Find the longest (draggiest) sentence index
  int _findLongestSentenceIndex(List<String> sentences) {
    if (sentences.isEmpty) return 0;
    int maxWords = 0;
    int maxIdx = 0;
    for (int i = 0; i < sentences.length; i++) {
      final wc = _wordCount(sentences[i]);
      if (wc > maxWords) {
        maxWords = wc;
        maxIdx = i;
      }
    }
    return maxIdx;
  }

  /// Compress a long sentence to roughly half its word count
  String _compressSentence(String sentence) {
    final words = sentence.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length <= 10) return sentence;

    // Remove filler words
    final fillerWords = {
      'basically', 'actually', 'really', 'just', 'very', 'quite',
      'simply', 'literally', 'honestly', 'obviously', 'essentially',
      'definitely', 'probably', 'certainly', 'absolutely',
    };

    final trimmedWords = words.where((w) => !fillerWords.contains(w.toLowerCase())).toList();

    // If still long, take the first 60% of meaningful words
    if (trimmedWords.length > 12) {
      final cutPoint = (trimmedWords.length * 0.6).ceil();
      final compressed = trimmedWords.sublist(0, cutPoint).join(' ');
      // Ensure it ends with punctuation
      if (!compressed.endsWith('.') && !compressed.endsWith('!') && !compressed.endsWith('?')) {
        return '$compressed.';
      }
      return compressed;
    }

    return trimmedWords.join(' ');
  }

  /// Generate a genuinely stronger title from the user's actual title
  String _generateStrongerTitle(String originalTitle, ChannelGraph channel) {
    final lower = originalTitle.toLowerCase();
    final hasNumber = RegExp(r'\d').hasMatch(originalTitle);
    final hasQuestion = originalTitle.contains('?');
    final hasParenthetical = originalTitle.contains('(');

    // If the title is already strong (has number + tension), amplify with stakes
    if (hasNumber && !hasParenthetical) {
      return '$originalTitle (The Real Numbers)';
    }

    // If the title is a plain statement, convert to contrarian question
    if (!hasQuestion && !hasNumber && !hasParenthetical) {
      // Extract core subject (first 6 meaningful words)
      final words = originalTitle.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      if (words.length >= 3) {
        final subject = words.take(min(6, words.length)).join(' ');

        // Check if it starts with "Why" or "How" already
        if (lower.startsWith('why') || lower.startsWith('how')) {
          return '$originalTitle (And Why 90% Get This Wrong)';
        }

        // Convert to "Why X Is Wrong" contrarian format
        return 'Why $subject Is Not What You Think';
      }
    }

    // If title has a question but no stakes
    if (hasQuestion && !hasParenthetical) {
      return originalTitle.replaceAll('?', ' (The Data Will Surprise You)?');
    }

    // Fallback: Add a curiosity gap parenthetical
    if (!hasParenthetical) {
      // Use channel's top video as social proof if available
      if (channel.recentVideos.isNotEmpty) {
        final topVideo = List<ChannelRecentVideo>.from(channel.recentVideos)
          ..sort((a, b) => b.views.compareTo(a.views));
        final topViews = topVideo.first.views;
        if (topViews > 10000) {
          return '$originalTitle (From the Creator Behind ${(topViews / 1000).toStringAsFixed(0)}K+ Views)';
        }
      }
      return '$originalTitle (What Nobody Tells You)';
    }

    return originalTitle;
  }

  /// Run Pre-Flight Content Stress Test on draft Title + Hook Script
  Future<SimulationResult> runSimulation({
    required String title,
    required String draftScript,
    required BlueprintFormat format,
    required ChannelGraph channel,
  }) async {
    await Future.delayed(const Duration(milliseconds: 950));

    final normalizedTitle = title.trim().toLowerCase();
    final normalizedScript = draftScript.trim().toLowerCase();
    final sentences = _splitSentences(draftScript);
    final totalWords = _wordCount(draftScript);

    // =========================================================================
    // 1. HOOK STRENGTH SCORE (0.0 to 10.0)
    // =========================================================================
    double hookScore = 5.0;

    // A. Opening sentence power analysis
    if (sentences.isNotEmpty) {
      final opener = sentences.first.toLowerCase();
      final openerWords = _wordCount(sentences.first);

      // Strong opener: starts with tension, question, or specific metric
      if (RegExp(r'^\d|^₹|^\$').hasMatch(opener)) hookScore += 1.5; // Leads with number
      if (opener.contains('?')) hookScore += 0.8;
      if (openerWords <= 12) hookScore += 0.6; // Punchy
      if (openerWords > 25) hookScore -= 0.8; // Too wordy for an opener

      // Power word in first sentence
      final powerWords = ['never', 'stop', 'mistake', 'why', 'secret', 'truth', 'real', 'cost', 'wrong', 'fail', 'hidden'];
      if (powerWords.any((pw) => opener.contains(pw))) hookScore += 1.0;
    }

    // B. Fluff detection & penalty
    final fluffPhrases = [
      'hey guys', 'welcome back', 'in this video', 'today i want to talk',
      'today we are going to', 'make sure to subscribe', 'like and share',
      'before we start', 'before we begin', 'so basically', 'in my opinion',
      'without further ado', 'what is up', 'hey everyone',
    ];
    String? detectedFluff;
    for (final fluff in fluffPhrases) {
      if (normalizedScript.contains(fluff)) {
        detectedFluff = fluff;
        hookScore -= 2.0;
        break;
      }
    }

    // C. Payoff speed analysis
    final highTensionIdx = _findHighTensionIndex(sentences);
    if (highTensionIdx == 0) {
      hookScore += 1.2; // Payoff is already front-loaded
    } else if (highTensionIdx == 1) {
      hookScore += 0.5; // Payoff in second sentence is okay
    } else if (highTensionIdx >= 2) {
      hookScore -= 0.6; // Payoff buried too deep
    }

    // D. Title curiosity analysis
    if (normalizedTitle.contains('?')) hookScore += 0.3;
    if (RegExp(r'\d').hasMatch(normalizedTitle)) hookScore += 0.5;
    if (normalizedTitle.contains('(') && normalizedTitle.contains(')')) hookScore += 0.4;
    final titlePowerWords = ['why', 'stop', 'never', 'truth', 'real', 'mistake', 'cost', 'secret', 'hidden', 'wrong'];
    if (titlePowerWords.any((pw) => normalizedTitle.contains(pw))) hookScore += 0.6;

    // E. Sentence variety & pacing
    if (sentences.length >= 3) {
      final wordCounts = sentences.map(_wordCount).toList();
      final hasVariety = wordCounts.any((w) => w <= 8) && wordCounts.any((w) => w >= 15);
      if (hasVariety) hookScore += 0.4; // Good rhythm variety
    }

    // F. Visual/production direction present
    final hasVisualCue = normalizedScript.contains('[visual') ||
        normalizedScript.contains('[cut') ||
        normalizedScript.contains('[split') ||
        normalizedScript.contains('[graphic') ||
        normalizedScript.contains('[b-roll');
    if (hasVisualCue) hookScore += 0.6;

    // G. Word count check
    if (totalWords < 8) hookScore -= 1.5;
    if (totalWords > 85 && format == BlueprintFormat.short) hookScore -= 0.8;

    hookScore = (hookScore.clamp(3.0, 9.8) * 10).round() / 10.0;

    // =========================================================================
    // 2. AUDIENCE RESONANCE SCORE
    // =========================================================================
    double resonanceBonus = 0.0;
    if (channel.niche.isNotEmpty) {
      final nicheWords = channel.niche.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 3);
      for (final nw in nicheWords) {
        if (normalizedTitle.contains(nw) || normalizedScript.contains(nw)) {
          resonanceBonus += 0.4;
        }
      }
    }
    for (final cluster in channel.topTopicClusters) {
      final cWords = cluster.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 3);
      for (final cw in cWords) {
        if (normalizedTitle.contains(cw) || normalizedScript.contains(cw)) {
          resonanceBonus += 0.3;
        }
      }
    }

    final resonanceScore =
        ((hookScore * 0.9 + resonanceBonus + 0.3).clamp(3.5, 9.9) * 10).round() / 10.0;

    // =========================================================================
    // 3. PERFORMANCE TIER
    // =========================================================================
    PerformanceTier tier;
    if (hookScore >= 8.5) {
      tier = PerformanceTier.topOutlier;
    } else if (hookScore >= 7.0) {
      tier = PerformanceTier.aboveMedian;
    } else if (hookScore >= 5.2) {
      tier = PerformanceTier.averageBaseline;
    } else {
      tier = PerformanceTier.highFlopRisk;
    }

    // =========================================================================
    // 4. RETENTION HAZARD TIMELINE
    // =========================================================================
    final hazards = <RetentionHazard>[];

    if (hookScore < 8.5 && sentences.isNotEmpty) {
      // Hazard 1: Delayed Payoff (the high-tension sentence isn't first)
      if (highTensionIdx >= 2 && sentences.length > 2) {
        hazards.add(
          RetentionHazard(
            startSeconds: 8,
            endSeconds: 15,
            severity: HazardSeverity.critical,
            dropOffRiskPercentage: 42,
            title: 'Payoff Buried at Sentence ${highTensionIdx + 1}',
            explanation:
                'Your strongest claim ("${_truncate(sentences[highTensionIdx], 60)}") appears ${highTensionIdx + 1} sentences deep. Viewers decide to stay or leave within 5 seconds. Move this forward.',
            flaggedScriptLine: sentences[highTensionIdx],
          ),
        );
      } else if (detectedFluff != null) {
        final fluffSentence = sentences.firstWhere(
          (s) => s.toLowerCase().contains(detectedFluff!),
          orElse: () => sentences.first,
        );
        hazards.add(
          RetentionHazard(
            startSeconds: 0,
            endSeconds: 6,
            severity: HazardSeverity.critical,
            dropOffRiskPercentage: 48,
            title: 'Generic Intro Fluff Detected',
            explanation:
                '"$detectedFluff" causes immediate swipe-away. The first 3 seconds must deliver tension, not pleasantries.',
            flaggedScriptLine: fluffSentence,
          ),
        );
      }

      // Hazard 2: Pacing Drag (a sentence is way too long)
      final longestIdx = _findLongestSentenceIndex(sentences);
      final longestWc = _wordCount(sentences[longestIdx]);
      if (longestWc > 25) {
        hazards.add(
          RetentionHazard(
            startSeconds: 18,
            endSeconds: 26,
            severity: HazardSeverity.warning,
            dropOffRiskPercentage: 28,
            title: 'Pacing Drag: $longestWc-Word Sentence',
            explanation:
                'This $longestWc-word sentence creates a pacing lull. Split it into 2 shorter punchy statements and insert a visual cut between them.',
            flaggedScriptLine: sentences[longestIdx],
          ),
        );
      }

      // Hazard 3: No visual direction in script
      if (!hasVisualCue && sentences.length >= 2) {
        hazards.add(
          RetentionHazard(
            startSeconds: 24,
            endSeconds: 30,
            severity: HazardSeverity.minor,
            dropOffRiskPercentage: 18,
            title: 'No Visual Pattern Interrupt',
            explanation:
                'Pure narration without visual cuts loses 18% of viewers by second 25. Insert a [B-Roll] or [VISUAL CUT] direction after your opening hook.',
            flaggedScriptLine: sentences.length > 1 ? sentences[1] : sentences.last,
          ),
        );
      }
    }

    // =========================================================================
    // 5. PRESCRIPTIVE FIXES (Genuine script rewrites)
    // =========================================================================
    final fixes = <PrescriptiveFix>[];

    // Fix 1: Hook Restructure — move the strongest sentence to position 1
    if (sentences.length >= 2 && highTensionIdx > 0) {
      final strongSentence = sentences[highTensionIdx];
      final weakOpener = sentences[0];

      // Build restructured opening: lead with strong sentence, then follow with context
      final restructured =
          '$strongSentence\n\n${sentences.where((s) => s != strongSentence).take(2).join(' ')}';

      fixes.add(
        PrescriptiveFix(
          id: 'fix_hook',
          fixType: 'Hook Restructure',
          description:
              'Your strongest claim is buried at sentence ${highTensionIdx + 1}. This fix moves it to the opening line and restructures the flow for immediate tension.',
          originalSnippet: weakOpener,
          replacementSnippet: restructured,
          scoreLift: 1.6,
          isApplied: false,
        ),
      );
    } else if (detectedFluff != null) {
      final fluffSentence = sentences.firstWhere(
        (s) => s.toLowerCase().contains(detectedFluff!),
        orElse: () => sentences.first,
      );
      // Replace fluff with a direct rewrite using the next sentence's content
      final nextContent = sentences.length > 1 ? sentences[1] : 'The data behind this changes everything.';
      fixes.add(
        PrescriptiveFix(
          id: 'fix_hook',
          fixType: 'Eliminate Intro Fluff',
          description:
              'Remove "$detectedFluff" and lead directly with your core thesis.',
          originalSnippet: fluffSentence,
          replacementSnippet: nextContent,
          scoreLift: 1.8,
          isApplied: false,
        ),
      );
    } else {
      // Opening is already decent — suggest a power-word lead-in
      final opener = sentences.isNotEmpty ? sentences.first : draftScript;
      fixes.add(
        PrescriptiveFix(
          id: 'fix_hook',
          fixType: 'Power Opening',
          description:
              'Add a 1-line tension hook before your current opener to stop the scroll.',
          originalSnippet: opener,
          replacementSnippet:
              'This single detail changes everything you assumed.\n\n$opener',
          scoreLift: 0.8,
          isApplied: hookScore >= 8.0,
        ),
      );
    }

    // Fix 2: Title Amplification — generate a genuinely stronger title
    final amplifiedTitle = _generateStrongerTitle(title, channel);
    if (amplifiedTitle != title) {
      fixes.add(
        PrescriptiveFix(
          id: 'fix_title',
          fixType: 'Title Curiosity Amplifier',
          description:
              'Your current title lacks a curiosity gap or specific stakes. This rewrite adds proven click-through patterns.',
          originalSnippet: title,
          replacementSnippet: amplifiedTitle,
          scoreLift: 0.9,
          isApplied: false,
        ),
      );
    }

    // Fix 3: Sentence Compression + Visual Cut — find the longest sentence and split it
    if (sentences.length >= 2) {
      final longestIdx = _findLongestSentenceIndex(sentences);
      final longestSentence = sentences[longestIdx];
      final longestWc = _wordCount(longestSentence);

      if (longestWc > 15) {
        final compressed = _compressSentence(longestSentence);
        final withVisualCut = '$compressed\n[VISUAL CUT: High-contrast proof on screen]';

        fixes.add(
          PrescriptiveFix(
            id: 'fix_pacing',
            fixType: 'Pacing Cut + Visual Break',
            description:
                'This $longestWc-word sentence drags the pacing. Compressed to ${_wordCount(compressed)} words with a visual interrupt to re-engage attention.',
            originalSnippet: longestSentence,
            replacementSnippet: withVisualCut,
            scoreLift: 1.0,
            isApplied: false,
          ),
        );
      } else if (!hasVisualCue) {
        // If no long sentence but no visual cue, suggest adding one
        final midSentence = sentences[sentences.length ~/ 2];
        fixes.add(
          PrescriptiveFix(
            id: 'fix_pacing',
            fixType: 'Visual Pattern Interrupt',
            description:
                'Insert a visual cut at the midpoint to prevent narration fatigue.',
            originalSnippet: midSentence,
            replacementSnippet:
                '$midSentence\n[B-ROLL: Supporting footage or data graphic]',
            scoreLift: 0.6,
            isApplied: false,
          ),
        );
      }
    }

    return SimulationResult(
      id: 'sim_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      draftScript: draftScript,
      format: format,
      hookScore: hookScore,
      resonanceScore: resonanceScore,
      performanceTier: tier,
      hazards: hazards,
      fixes: fixes,
      createdAt: DateTime.now(),
    );
  }

  /// Truncate text for display
  String _truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen)}...';
  }

  /// Apply a prescriptive fix and return the boosted SimulationResult
  SimulationResult applyPrescriptiveFix({
    required SimulationResult currentResult,
    required String fixId,
  }) {
    final updatedFixes = currentResult.fixes.map((f) {
      if (f.id == fixId) {
        return f.copyWith(isApplied: true);
      }
      return f;
    }).toList();

    final targetFix = currentResult.fixes.firstWhere((f) => f.id == fixId);
    final newScore = min(
        9.8,
        ((currentResult.hookScore + targetFix.scoreLift) * 10).round() /
            10.0);
    final newResonance = min(
        9.8,
        ((currentResult.resonanceScore + (targetFix.scoreLift * 0.7)) * 10)
                .round() /
            10.0);

    // Clear hazards that this fix resolves
    final remainingHazards = currentResult.hazards.where((h) {
      if (fixId == 'fix_hook') {
        return h.startSeconds > 16; // Clears opening hazards
      }
      if (fixId == 'fix_pacing') {
        return h.startSeconds < 16; // Clears pacing/visual hazards
      }
      return true;
    }).toList();

    return currentResult.copyWith(
      hookScore: newScore,
      resonanceScore: newResonance,
      performanceTier: newScore >= 8.5
          ? PerformanceTier.topOutlier
          : newScore >= 7.0
              ? PerformanceTier.aboveMedian
              : currentResult.performanceTier,
      fixes: updatedFixes,
      hazards: remainingHazards,
    );
  }
}
