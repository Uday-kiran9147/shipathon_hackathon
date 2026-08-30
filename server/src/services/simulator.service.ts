export interface SimulationInput {
  creatorId: string;
  medianViews: number;
  title: string;
  script: string;
  format: 'longForm' | 'short';
}

export interface DimensionScores {
  hookStrength: number;
  audienceResonance: number;
  novelty: number;
  topicMomentum: number;
  clarity: number;
  pacing: number;
  creatorFit: number;
  overallScore: number;
}

export interface RetentionHazardItem {
  timestampRange: string;
  startSeconds: number;
  endSeconds: number;
  severity: 'critical' | 'warning' | 'minor';
  dropOffPercentage: number;
  flaggedSentence: string;
  whyReason: string;
  fixSuggestion: string;
}

export interface PrescriptiveFixItem {
  id: string;
  problem: string;
  originalSnippet: string;
  replacementSnippet: string;
  impactScoreLift: number;
  projectedScoreAfter: number;
}

export interface SimulationResultPayload {
  scores: DimensionScores;
  baselineMedianViews: number;
  viewsMultiplier: number;
  projectedViews: number;
  performanceLadder: {
    '0.7x': number;
    '1.0x': number;
    '1.5x': number;
    '2.0x': number;
  };
  hazards: RetentionHazardItem[];
  fixes: PrescriptiveFixItem[];
}

export class SimulatorService {
  /**
   * Run Pre-Flight Content Stress Test evaluating the 7 dimensions + Views Projection Model
   */
  evaluateScript(input: SimulationInput): SimulationResultPayload {
    const sentences = this.splitSentences(input.script);
    const title = input.title.trim();
    const script = input.script.trim();
    const median = Math.max(1000, input.medianViews || 18400);

    // 1. Hook Strength Scoring (0 - 10)
    let hookStrength = 6.2;
    const opener = (sentences[0] || '').toLowerCase();
    if (/\d|₹|\$|%/.test(opener)) hookStrength += 1.4;
    if (opener.includes('?')) hookStrength += 0.8;
    if (this.containsPowerWord(opener)) hookStrength += 1.2;
    if (opener.startsWith('today') || opener.startsWith('in this video') || opener.startsWith('hey guys')) {
      hookStrength -= 2.0;
    }
    hookStrength = parseFloat(Math.min(9.8, Math.max(3.0, hookStrength)).toFixed(1));

    // 2. Multi-dimensional scores
    const audienceResonance = parseFloat(Math.min(9.9, Math.max(4.0, hookStrength * 0.95 + 0.4)).toFixed(1));
    const novelty = parseFloat((7.5 + (Math.sin(title.length) * 0.8)).toFixed(1));
    const topicMomentum = 8.6;
    const clarity = sentences.some((s) => s.split(' ').length > 25) ? 7.2 : 8.9;
    const pacing = sentences.length >= 3 ? 8.4 : 7.0;
    const creatorFit = 9.0;

    const overallScore = parseFloat(
      (
        hookStrength * 0.28 +
        audienceResonance * 0.22 +
        novelty * 0.15 +
        topicMomentum * 0.15 +
        clarity * 0.10 +
        pacing * 0.10
      ).toFixed(1)
    );

    // 3. Views Projection Formula:
    // baseline = medianViews
    // multiplier = (topicMomentum/10) * (hookStrength/10) * (audienceResonance/10) * (novelty/10) * calibration
    const compositeMultiplier = parseFloat(
      Math.max(
        0.4,
        (
          (topicMomentum / 9.0) *
          (hookStrength / 8.5) *
          (audienceResonance / 8.5) *
          (novelty / 8.0) *
          1.4
        )
      ).toFixed(2)
    );

    const projectedViews = Math.round(median * compositeMultiplier);

    // 4. Retention Hazard Timeline
    const hazards: RetentionHazardItem[] = [];
    if (sentences.length > 1) {
      const genericSentence = sentences.find(
        (s) =>
          s.toLowerCase().startsWith('today') ||
          s.toLowerCase().startsWith('in this video') ||
          s.toLowerCase().includes('welcome back')
      );

      if (genericSentence) {
        hazards.push({
          timestampRange: '0:00 - 0:06',
          startSeconds: 0,
          endSeconds: 6,
          severity: 'critical',
          dropOffPercentage: 48,
          flaggedSentence: genericSentence,
          whyReason: 'Low information density; viewer already knows the topic and expects immediate tension.',
          fixSuggestion: 'Eliminate greeting and lead directly with your high-stakes thesis.',
        });
      }

      const longSentence = sentences.find((s) => s.split(' ').length > 20);
      if (longSentence) {
        hazards.push({
          timestampRange: '0:12 - 0:18',
          startSeconds: 12,
          endSeconds: 18,
          severity: 'warning',
          dropOffPercentage: 32,
          flaggedSentence: longSentence,
          whyReason: 'Pacing lull caused by prolonged complex sentence before payoff.',
          fixSuggestion: 'Split into 2 punchy 6-word sentences and insert a visual proof cut.',
        });
      }
    }

    // 5. Three Prescriptive Fixes
    const fixes: PrescriptiveFixItem[] = [
      {
        id: 'fix_hook_1',
        problem: 'Generic introductory pacing',
        originalSnippet: sentences[0] || script,
        replacementSnippet: `I gave an AI agent 30 minutes to rebuild my core architecture. What happened next forced us to rethink our entire workflow.`,
        impactScoreLift: 0.8,
        projectedScoreAfter: Math.min(9.8, parseFloat((overallScore + 0.8).toFixed(1))),
      },
      {
        id: 'fix_title_2',
        problem: 'Title lacks explicit stakes or curiosity gap',
        originalSnippet: title,
        replacementSnippet: `${title} (And Why 90% Get This Wrong)`,
        impactScoreLift: 0.6,
        projectedScoreAfter: Math.min(9.8, parseFloat((overallScore + 0.6).toFixed(1))),
      },
      {
        id: 'fix_visual_3',
        problem: 'No visual pattern interrupt in first 15 seconds',
        originalSnippet: sentences[1] || 'Explanation of system',
        replacementSnippet: `${sentences[1] || 'Explanation of system'}\n[VISUAL CUT: High-contrast benchmark graph on screen]`,
        impactScoreLift: 0.4,
        projectedScoreAfter: Math.min(9.8, parseFloat((overallScore + 0.4).toFixed(1))),
      },
    ];

    return {
      scores: {
        hookStrength,
        audienceResonance,
        novelty,
        topicMomentum,
        clarity,
        pacing,
        creatorFit,
        overallScore,
      },
      baselineMedianViews: median,
      viewsMultiplier: compositeMultiplier,
      projectedViews,
      performanceLadder: {
        '0.7x': Math.round(median * 0.7),
        '1.0x': median,
        '1.5x': Math.round(median * 1.5),
        '2.0x': Math.round(median * 2.0),
      },
      hazards,
      fixes,
    };
  }

  private splitSentences(text: string): string[] {
    return text
      .split(/(?<=[.!?\n])\s+/)
      .map((s) => s.trim())
      .filter((s) => s.length > 0);
  }

  private containsPowerWord(text: string): boolean {
    const words = [
      'never', 'stop', 'mistake', 'why', 'secret', 'truth', 'real',
      'cost', 'wrong', 'fail', 'hidden', 'detail', 'shocking', 'formula',
      'warning', 'tested', 'breakdown', 'changes', 'proven',
    ];
    return words.some((w) => text.includes(w));
  }
}
