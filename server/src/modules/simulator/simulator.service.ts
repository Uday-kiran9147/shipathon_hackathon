import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EvaluateSimulationDto } from './dto/evaluate-simulation.dto';
import { NICHE_TAXONOMY, NicheProfile, detectNicheKey, checkDomainMismatch } from './niche-taxonomy';

export interface DimensionScores {
  hookStrength: number;
  audienceResonance: number;
  novelty: number;
  topicMomentum: number;
  clarity: number;
  pacing: number;
  creatorFit: number;
  authenticityScore: number;
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

@Injectable()
export class SimulatorService {
  private readonly logger = new Logger(SimulatorService.name);
  private readonly apiKey: string;
  private readonly model: string;

  constructor(private readonly configService: ConfigService) {
    this.apiKey = this.configService.get<string>('geminiApiKey', '');
    this.model = this.configService.get<string>('geminiModel', 'gemini-3.6-flash');
  }

  async evaluateScript(input: EvaluateSimulationDto): Promise<SimulationResultPayload> {
    const nicheKey = detectNicheKey(input.niche || '');
    const nicheProfile = NICHE_TAXONOMY[nicheKey];

    if (this.apiKey) {
      try {
        return await this.evaluateWithGemini(input, nicheProfile);
      } catch (e: any) {
        this.logger.warn(`Gemini simulator fallback: ${e.message}`);
      }
    }

    return this.evaluateStatically(input, nicheProfile);
  }

  // ─── Gemini path ──────────────────────────────────────────────────────────

  private async evaluateWithGemini(
    input: EvaluateSimulationDto,
    nicheProfile: NicheProfile,
  ): Promise<SimulationResultPayload> {
    const prompt = this.buildEvalPrompt(input, nicheProfile);
    const body = JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.4,
        topP: 0.9,
        maxOutputTokens: 4096,
        responseMimeType: 'application/json',
      },
    });

    const data = await this.fetchGeminiWithRetry(body);
    const rawJson = data.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!rawJson) throw new Error('Empty Gemini response');

    const parsed = JSON.parse(rawJson);
    const s = parsed.scores || {};
    const median = Math.max(1000, input.medianViews || 18400);

    const hookStrength = this.clamp(s.hookStrength ?? 6.0, 3.0, 9.8);
    const audienceResonance = this.clamp(s.audienceResonance ?? hookStrength * 0.95 + 0.4, 3.0, 9.9);
    const novelty = this.clamp(s.novelty ?? 7.5, 3.0, 9.8);
    const topicMomentum = this.clamp(s.topicMomentum ?? nicheProfile.baseTopicMomentum, 3.0, 9.8);
    const clarity = this.clamp(s.clarity ?? 8.0, 3.0, 9.9);
    const pacing = this.clamp(s.pacing ?? 8.0, 3.0, 9.9);
    const creatorFit = this.clamp(s.creatorFit ?? 7.0, 3.0, 9.9);
    const authenticityScore = this.clamp(s.authenticityScore ?? 7.0, 3.0, 9.9);

    const overallScore = this.round(
      hookStrength * 0.27 +
      audienceResonance * 0.21 +
      novelty * 0.15 +
      topicMomentum * 0.13 +
      clarity * 0.10 +
      pacing * 0.08 +
      authenticityScore * 0.06,
    );

    const compositeMultiplier = this.round(
      Math.max(0.4, (topicMomentum / 9.0) * (hookStrength / 8.5) * (audienceResonance / 8.5) * (novelty / 8.0) * 1.4),
    );

    return {
      scores: { hookStrength, audienceResonance, novelty, topicMomentum, clarity, pacing, creatorFit, authenticityScore, overallScore },
      baselineMedianViews: median,
      viewsMultiplier: compositeMultiplier,
      projectedViews: Math.round(median * compositeMultiplier),
      performanceLadder: {
        '0.7x': Math.round(median * 0.7),
        '1.0x': median,
        '1.5x': Math.round(median * 1.5),
        '2.0x': Math.round(median * 2.0),
      },
      hazards: this.normalizeHazards(parsed.hazards || []),
      fixes: this.normalizeFixes(parsed.fixes || [], overallScore),
    };
  }

  private buildEvalPrompt(input: EvaluateSimulationDto, nicheProfile: NicheProfile): string {
    const rawScript = input.script || input.draftScript || '';
    const niche = input.niche || 'general content creator';

    return `You are a YouTube performance analyst evaluating a ${niche} creator's draft script.

CHANNEL CONTEXT:
- Niche: ${niche}
- Signature hook style: "${input.signatureHookStyle || 'not specified'}"
- Engagement velocity (likes+comments per 1K views): ${input.engagementVelocity ?? 'unknown'}
- Top audience demand clusters: ${JSON.stringify(input.topDemandClusters || [])}
- Outlier formats (overperforming on this channel): ${(input.outlierVideoFormats || []).join(', ') || 'not specified'}
- Topic performance multipliers: ${JSON.stringify(input.topicMultipliers || [])}

NICHE AUTHENTICITY MARKERS: ${nicheProfile.authenticityMarkers.join(', ')}
NICHE POWER WORDS: ${nicheProfile.powerWords.slice(0, 8).join(', ')}
NICHE RETENTION HAZARDS: ${nicheProfile.retentionHazards.join(', ')}

DRAFT TITLE: "${input.title}"
DRAFT SCRIPT:
---
${rawScript.substring(0, 1400)}
---

CRITICAL DOMAIN & AUTHENTICITY GUARDRAIL:
- This creator's established channel domain is "${niche}".
- DOMAIN CHECK: If the draft topic or script attempts an unrelated domain (e.g., a Tech creator attempting Cooking, or a Lifestyle creator attempting low-level Systems C++ code), penalize "creatorFit" and "authenticityScore" severely (down to 2.0-4.0), generate a critical "Domain Mismatch" retention hazard warning about audience drop-off/bounce, and lower projected view multipliers.
- If the draft is aligned with the creator's domain and signature style, score accurately on merits.

Evaluate this draft and return ONLY valid JSON (no markdown fences, no explanation) matching this exact schema:
{
  "scores": {
    "hookStrength": <0-10, how powerfully the opener grabs attention for THIS niche>,
    "audienceResonance": <0-10, alignment with audience demand clusters and this community's language>,
    "novelty": <0-10, how fresh/differentiated vs typical ${niche} content on YouTube>,
    "topicMomentum": <0-10, alignment with this creator's high-performing topic clusters>,
    "clarity": <0-10, information density and sentence clarity>,
    "pacing": <0-10, rhythm and sentence structure variety>,
    "creatorFit": <0-10, how well this matches the creator's established domain and signature style>,
    "authenticityScore": <0-10, does this sound like THIS creator's authentic domain voice or off-niche drift>
  },
  "hazards": [
    {
      "timestampRange": "<e.g. 0:00 - 0:08>",
      "startSeconds": <int>,
      "endSeconds": <int>,
      "severity": "<critical|warning|minor>",
      "dropOffPercentage": <int>,
      "flaggedSentence": "<exact quote from the submitted script above>",
      "whyReason": "<specific reason this causes drop-off for a ${niche} audience>",
      "fixSuggestion": "<concrete rewrite in this creator's niche voice>"
    }
  ],
  "fixes": [
    {
      "id": "fix_hook",
      "problem": "<specific hook problem found in this script>",
      "originalSnippet": "<exact quote from the script>",
      "replacementSnippet": "<rewrite matching signature style: ${input.signatureHookStyle || 'creator voice'}>",
      "impactScoreLift": <0.4-1.2>,
      "projectedScoreAfter": <overallScore + lift>
    },
    {
      "id": "fix_title",
      "problem": "<title-specific issue for ${niche} audience>",
      "originalSnippet": "${input.title}",
      "replacementSnippet": "<improved title using ${niche} niche conventions>",
      "impactScoreLift": <0.3-0.8>,
      "projectedScoreAfter": <overallScore + lift>
    },
    {
      "id": "fix_pacing",
      "problem": "<pacing or visual break issue>",
      "originalSnippet": "<quote from script>",
      "replacementSnippet": "<improved version with pacing note for ${niche} content>",
      "impactScoreLift": <0.2-0.6>,
      "projectedScoreAfter": <overallScore + lift>
    }
  ]
}

RULES:
- flaggedSentence and originalSnippet must be exact quotes from the submitted script or title.
- replacementSnippet must be in ${niche} niche voice — not generic YouTube advice.
- If the script is genuinely strong, give it high scores. Do not penalise good writing.
- Return ONLY the JSON object.`;
  }

  private evaluateStatically(
    input: EvaluateSimulationDto,
    nicheProfile: NicheProfile,
  ): SimulationResultPayload {
    const rawScript = input.script || input.draftScript || '';
    const sentences = this.splitSentences(rawScript);
    const title = (input.title || 'Untitled Draft').trim();
    const median = Math.max(1000, input.medianViews || 18400);
    const opener = (sentences[0] || '').toLowerCase();

    // Check domain alignment between channel niche and draft script
    const domainCheck = checkDomainMismatch(input.niche || '', `${title} ${rawScript}`);

    // Hook — niche power words replace the generic list
    let hookStrength = 6.2;
    if (/\d|₹|\$|%/.test(opener)) hookStrength += 1.4;
    if (opener.includes('?')) hookStrength += 0.8;
    if (this.containsNichePowerWord(opener, nicheProfile)) hookStrength += 1.2;
    if (nicheProfile.retentionHazards.some((h) => opener.includes(h.toLowerCase()))) hookStrength -= 2.0;
    hookStrength = this.clamp(hookStrength, 3.0, 9.8);

    // Authenticity — did the hook match the creator's signature style & domain?
    let authenticityScore = this.computeStaticAuthenticityScore(opener, input, nicheProfile);

    // Topic momentum — boosted by real multipliers when provided
    const topMultiplier = (input.topicMultipliers || []).reduce(
      (max, t) => Math.max(max, t.multiplier),
      1.0,
    );
    let topicMomentum = this.clamp(nicheProfile.baseTopicMomentum * Math.min(topMultiplier, 1.2), 3.0, 9.8);

    let creatorFit = this.clamp(7.0 + authenticityScore * 0.2, 3.0, 9.9);

    // If there is an irreconcilable domain mismatch (e.g. Tech creator doing Cooking):
    if (domainCheck.isMismatch) {
      creatorFit = this.clamp(creatorFit - 4.5, 2.2, 4.0);
      authenticityScore = this.clamp(authenticityScore - 4.0, 2.0, 3.8);
      topicMomentum = this.clamp(topicMomentum - 3.0, 2.5, 5.0);
    }

    const audienceResonance = this.clamp(
      domainCheck.isMismatch ? 3.5 : hookStrength * 0.95 + 0.4,
      2.5,
      9.9,
    );
    // Novelty lifted by breadth of demand clusters
    const novelty = this.clamp(6.5 + Math.min(2.0, (input.topDemandClusters?.length ?? 0) * 0.4), 3.0, 9.8);
    const clarity = sentences.some((s) => s.split(' ').length > 25) ? 7.2 : 8.9;
    const pacing = sentences.length >= 3 ? 8.4 : 7.0;

    const overallScore = this.round(
      hookStrength * 0.27 +
      audienceResonance * 0.21 +
      novelty * 0.15 +
      topicMomentum * 0.13 +
      clarity * 0.10 +
      pacing * 0.08 +
      authenticityScore * 0.06,
    );

    let compositeMultiplier = this.round(
      Math.max(0.4, (topicMomentum / 9.0) * (hookStrength / 8.5) * (audienceResonance / 8.5) * (novelty / 8.0) * 1.4),
    );

    if (domainCheck.isMismatch) {
      compositeMultiplier = this.round(Math.max(0.35, compositeMultiplier * 0.55));
    }

    return {
      scores: {
        hookStrength,
        audienceResonance,
        novelty,
        topicMomentum,
        clarity,
        pacing,
        creatorFit,
        authenticityScore,
        overallScore,
      },
      baselineMedianViews: median,
      viewsMultiplier: compositeMultiplier,
      projectedViews: Math.round(median * compositeMultiplier),
      performanceLadder: {
        '0.7x': Math.round(median * 0.7),
        '1.0x': median,
        '1.5x': Math.round(median * 1.5),
        '2.0x': Math.round(median * 2.0),
      },
      hazards: this.buildNicheHazards(sentences, title, input, nicheProfile, domainCheck),
      fixes: this.buildNicheFixes(sentences, title, input, nicheProfile, overallScore, domainCheck),
    };
  }

  private computeStaticAuthenticityScore(
    opener: string,
    input: EvaluateSimulationDto,
    nicheProfile: NicheProfile,
  ): number {
    let score = 7.0;

    // Hook phrasing overlaps with signature style?
    const sigStyle = (input.signatureHookStyle || '').toLowerCase();
    if (sigStyle) {
      const sigWords = sigStyle.split(/\s+/).filter((w) => w.length > 4);
      const matchCount = sigWords.filter((w) => opener.includes(w)).length;
      score += Math.min(1.5, matchCount * 0.5);
    }

    // Title mentions a high-demand topic?
    const titleLower = (input.title || '').toLowerCase();
    const topDemand = input.topDemandClusters?.[0]?.topic?.toLowerCase() || '';
    if (topDemand && titleLower.includes(topDemand.split(' ')[0])) score += 0.8;

    // Format aligns with outlier formats?
    if (input.outlierVideoFormats?.length && input.format) {
      if (input.outlierVideoFormats.some((f) => f.toLowerCase().includes(input.format!))) score += 0.5;
    }

    // Niche authenticity markers present in the script?
    const scriptLower = (input.script || input.draftScript || '').toLowerCase();
    const markerHits = nicheProfile.authenticityMarkers.filter((m) =>
      scriptLower.includes(m.toLowerCase().split(' ')[0]),
    ).length;
    score += Math.min(1.0, markerHits * 0.3);

    return this.clamp(score, 3.0, 9.9);
  }

  private buildNicheHazards(
    sentences: string[],
    title: string,
    input: EvaluateSimulationDto,
    nicheProfile: NicheProfile,
    domainCheck?: { isMismatch: boolean; channelKey: string; scriptKey: string },
  ): RetentionHazardItem[] {
    const hazards: RetentionHazardItem[] = [];

    // Prepend Domain Mismatch critical hazard if detected
    if (domainCheck?.isMismatch) {
      hazards.push({
        timestampRange: '0:00 - 0:10',
        startSeconds: 0,
        endSeconds: 10,
        severity: 'critical',
        dropOffPercentage: 68,
        flaggedSentence: sentences[0] || title,
        whyReason: `Audience Domain Mismatch: Your channel's community is calibrated for ${input.niche || 'your domain'}. This ${domainCheck.scriptKey} concept causes immediate subscriber bounce and algorithmic confusion.`,
        fixSuggestion: `Pivot the angle back to ${input.niche || 'your core domain'}, or build an explicit technical bridge to your audience's domain.`,
      });
    }

    if (sentences.length <= 1) return hazards;

    const genericSentence = sentences.find((s) =>
      nicheProfile.retentionHazards.some((h) => s.toLowerCase().includes(h.toLowerCase())),
    );

    if (genericSentence) {
      hazards.push({
        timestampRange: '0:00 - 0:06',
        startSeconds: 0,
        endSeconds: 6,
        severity: 'critical',
        dropOffPercentage: 48,
        flaggedSentence: genericSentence,
        whyReason: 'Low information density opener — this niche audience expects immediate tension or a proof point.',
        fixSuggestion: `Lead directly with your high-stakes thesis. Niche pattern: "${nicheProfile.hookPatterns[0]}"`,
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
        whyReason: 'Pacing lull — complex sentence before payoff.',
        fixSuggestion: 'Split into 2 punchy sentences and add a visual cut.',
      });
    }

    return hazards;
  }

  private buildNicheFixes(
    sentences: string[],
    title: string,
    input: EvaluateSimulationDto,
    nicheProfile: NicheProfile,
    overallScore: number,
    domainCheck?: { isMismatch: boolean; channelKey: string; scriptKey: string },
  ): PrescriptiveFixItem[] {
    const topDemand = input.topDemandClusters?.[0]?.topic || 'your core topic';
    const hookPattern = nicheProfile.hookPatterns[0].replace('{topic}', topDemand);
    const powerWord = nicheProfile.powerWords[0];
    const powerWordCapitalized = powerWord.charAt(0).toUpperCase() + powerWord.slice(1);

    const fixes: PrescriptiveFixItem[] = [];

    // Prepend Domain Realignment fix if mismatched
    if (domainCheck?.isMismatch) {
      fixes.push({
        id: 'fix_domain_alignment',
        problem: `Domain Mismatch: Concept belongs to ${domainCheck.scriptKey} rather than ${input.niche || 'your niche'}`,
        originalSnippet: title,
        replacementSnippet: `How I Built a ${title} System in ${input.niche || 'My Tech Stack'}`,
        impactScoreLift: 1.8,
        projectedScoreAfter: Math.min(9.8, this.round(overallScore + 1.8)),
      });
    }

    fixes.push(
      {
        id: 'fix_hook',
        problem: `Hook does not match the established opener pattern for ${input.niche || 'this'} content`,
        originalSnippet: sentences[0] || (input.script || '').substring(0, 100) || 'Opening line',
        replacementSnippet: hookPattern,
        impactScoreLift: 0.8,
        projectedScoreAfter: Math.min(9.8, this.round(overallScore + 0.8)),
      },
      {
        id: 'fix_title',
        problem: `Title lacks explicit stakes for a ${input.niche || 'content'} audience`,
        originalSnippet: title,
        replacementSnippet: `${title} (${powerWordCapitalized} That 90% Get Wrong)`,
        impactScoreLift: 0.6,
        projectedScoreAfter: Math.min(9.8, this.round(overallScore + 0.6)),
      },
      {
        id: 'fix_pacing',
        problem: 'No visual pattern interrupt anchoring the first 15 seconds',
        originalSnippet: sentences[1] || sentences[0] || 'Second sentence',
        replacementSnippet:
          `${sentences[1] || sentences[0] || 'Second sentence'}\n[VISUAL CUT: ${nicheProfile.authenticityMarkers[0] || 'Key proof point on screen'}]`,
        impactScoreLift: 0.4,
        projectedScoreAfter: Math.min(9.8, this.round(overallScore + 0.4)),
      },
    );

    return fixes.slice(0, 3);
  }

  // ─── Normalizers for Gemini output ────────────────────────────────────────

  private normalizeHazards(raw: any[]): RetentionHazardItem[] {
    return raw.slice(0, 3).map((h) => ({
      timestampRange: h.timestampRange || '0:00 - 0:08',
      startSeconds: h.startSeconds ?? 0,
      endSeconds: h.endSeconds ?? 8,
      severity: (['critical', 'warning', 'minor'].includes(h.severity)
        ? h.severity
        : 'warning') as RetentionHazardItem['severity'],
      dropOffPercentage: h.dropOffPercentage ?? 30,
      flaggedSentence: h.flaggedSentence || '',
      whyReason: h.whyReason || '',
      fixSuggestion: h.fixSuggestion || '',
    }));
  }

  private normalizeFixes(raw: any[], overallScore: number): PrescriptiveFixItem[] {
    return raw.slice(0, 3).map((f) => ({
      id: f.id || 'fix_generic',
      problem: f.problem || '',
      originalSnippet: f.originalSnippet || '',
      replacementSnippet: f.replacementSnippet || '',
      impactScoreLift: f.impactScoreLift ?? 0.5,
      projectedScoreAfter: f.projectedScoreAfter ?? this.round(overallScore + 0.5),
    }));
  }

  // ─── Utilities ─────────────────────────────────────────────────────────────

  /// Gemini's flash models intermittently return 503 UNAVAILABLE / 429
  /// RESOURCE_EXHAUSTED under transient load spikes. Retrying the same
  /// overloaded model back-to-back often just hits the same congestion, so
  /// on a transient failure we rotate to secondary models before giving up
  /// to the static algorithmic fallback. gemini-flash-lite-latest runs on a
  /// separate, typically less-congested capacity pool from the full flash
  /// tier, so it's the last, most-likely-to-succeed model tried.
  private async fetchGeminiWithRetry(body: string): Promise<any> {
    const models = [...new Set([this.model, 'gemini-flash-latest', 'gemini-flash-lite-latest'])];
    let lastError: Error = new Error('Gemini request failed');
    for (const model of models) {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${this.apiKey}`;
      let isTransient = false;
      try {
        const res = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body,
          signal: AbortSignal.timeout(12000),
        });
        const data = await res.json();
        if (res.ok) return data;
        isTransient = res.status === 503 || res.status === 429;
        lastError = new Error(`Gemini API error ${res.status} (${model}): ${JSON.stringify(data.error || data)}`);
      } catch (e: any) {
        isTransient = true; // network errors / timeouts are also worth trying the next model
        lastError = e;
      }
      if (!isTransient) throw lastError;
    }
    throw lastError;
  }

  private splitSentences(text: string): string[] {
    return text
      .split(/(?<=[.!?\n])\s+/)
      .map((s) => s.trim())
      .filter((s) => s.length > 0);
  }

  private containsNichePowerWord(text: string, nicheProfile: NicheProfile): boolean {
    return nicheProfile.powerWords.some((w) => text.includes(w.toLowerCase()));
  }

  private clamp(val: number, min: number, max: number): number {
    return parseFloat(Math.min(max, Math.max(min, val)).toFixed(1));
  }

  private round(val: number): number {
    return parseFloat(val.toFixed(1));
  }
}
