import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MinedChannelData } from '../youtube/youtube.service';
import { VectorService } from '../vector/vector.service';

export interface StructuredBlueprint {
  id: string;
  title: string;
  format: 'longForm' | 'short';
  formatLabel: string;
  hookText: string;
  thumbnailConceptLeft: string;
  thumbnailConceptRight: string;
  thumbnailTag: string;
  dataProofReason: string;
  predictedMultiplier: number;
  convictionScore: number;
  categoryTag: string;
  demandEvidenceSummary: string;
  creatorAuthenticityProof: string;
  engagementContext: string;
  preEngineeredRetentionAnchors: string[];
}

@Injectable()
export class BriefingService {
  private readonly logger = new Logger(BriefingService.name);
  private readonly apiKey: string;
  private readonly model: string;

  constructor(
    private configService: ConfigService,
    private readonly vectorService: VectorService,
  ) {
    this.apiKey = this.configService.get<string>('geminiApiKey', '');
    this.model = this.configService.get<string>('geminiModel', 'gemini-3.7-flash');
  }

  async generateDailyBriefing(
    channel: MinedChannelData,
    creatorId?: string,
  ): Promise<StructuredBlueprint[]> {
    const vectorOutliers = creatorId
      ? await this.findVectorMatchedOutliers(creatorId, channel)
      : [];

    if (!this.apiKey) {
      return this.generateAlgorithmicBlueprints(channel, vectorOutliers);
    }

    try {
      const prompt = this.buildContextualPrompt(channel, vectorOutliers);
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${this.model}:generateContent?key=${this.apiKey}`;

      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 0.7,
            topP: 0.95,
            maxOutputTokens: 8192,
            responseMimeType: 'application/json',
          },
        }),
      });

      const data = await res.json();
      const rawJson = data.candidates?.[0]?.content?.parts?.[0]?.text;
      if (rawJson) {
        const parsed = this.parseJsonResponse(rawJson);
        if (parsed.length > 0) {
          return parsed;
        }
      }
      return this.generateAlgorithmicBlueprints(channel, vectorOutliers);
    } catch (e: any) {
      this.logger.warn(`Gemini generation fallback: ${e.message}`);
      return this.generateAlgorithmicBlueprints(channel, vectorOutliers);
    }
  }

  /// Find semantically-similar historical outlier videos via pgvector so the
  /// "Historical Outlier Sequel" blueprint is backed by real cosine-similarity
  /// matches instead of a generic topic guess.
  private async findVectorMatchedOutliers(
    creatorId: string,
    channel: MinedChannelData,
  ): Promise<{ title: string; views: number; performance_multiple: number }[]> {
    try {
      const seedText = [
        channel.niche,
        channel.audienceInsight?.topDemandClusters?.[0]?.topicKeyword,
        channel.topTopicClusters?.[0],
      ]
        .filter(Boolean)
        .join(' ');
      if (!seedText) return [];

      const outliers = await this.vectorService.findSemanticallySimilarOutliers(
        creatorId,
        seedText,
        1.3,
      );
      return (outliers || []).map((o: any) => ({
        title: o.title,
        views: Number(o.views) || 0,
        performance_multiple: Number(o.performance_multiple) || 1.0,
      }));
    } catch (e: any) {
      this.logger.debug(`Vector outlier match skipped: ${e.message}`);
      return [];
    }
  }

  private parseJsonResponse(rawJson: string): StructuredBlueprint[] {
    let text = rawJson.trim();
    if (text.startsWith('```json')) text = text.substring(7);
    else if (text.startsWith('```')) text = text.substring(3);
    if (text.endsWith('```')) text = text.substring(0, text.length - 3);
    text = text.trim();

    try {
      const parsed = JSON.parse(text);
      if (parsed.blueprints && Array.isArray(parsed.blueprints)) {
        return parsed.blueprints;
      }
    } catch (e: any) {
      this.logger.warn(`Failed to parse Gemini blueprint JSON: ${e.message}`);
    }
    return [];
  }

  private buildContextualPrompt(
    channel: MinedChannelData,
    vectorOutliers: { title: string; views: number; performance_multiple: number }[] = [],
  ): string {
    const topicLines = (channel.topicPerformanceMultipliers || [])
      .map((t) => `${t.topic.padEnd(24)} → ${t.multiple}x median (Avg ${t.averageViews} views)`)
      .join('\n');

    const videoLines = (channel.recentVideos || [])
      .slice(0, 6)
      .map((v, i) => {
        const commentLines = (v.topComments || [])
          .slice(0, 2)
          .map(
            (c) =>
              `    * Comment by ${c.authorDisplayName} (${c.likeCount} likes): "${c.text.replace(/"/g, "'").replace(/\n/g, ' ')}"`,
          )
          .join('\n');
        return `${i + 1}. "${v.title}" (${v.views} views, ${v.likes} likes)${commentLines ? '\n' + commentLines : ''}`;
      })
      .join('\n');

    const demandClusterLines = (channel.audienceInsight?.topDemandClusters || [])
      .slice(0, 4)
      .map((cluster) => {
        const quote = cluster.sampleComments?.[0];
        const quoteLine = quote
          ? `\n    Sample Quote by ${quote.authorDisplayName}: "${quote.text.replace(/"/g, "'").replace(/\n/g, ' ')}"`
          : '';
        return `  - Topic: "${cluster.topicKeyword}" | Requests: ${cluster.commentFrequency} | Upvotes: ${cluster.totalUpvotes} | DVI: ${cluster.demandVelocityIndex.toFixed(1)}${quoteLine}`;
      })
      .join('\n');

    const authenticityProfile = channel.authenticityProfile;

    const vectorOutlierLines = vectorOutliers
      .map((o) => `  - "${o.title}" (${o.views} views, ${o.performance_multiple.toFixed(1)}x median) — semantically similar to this channel's current niche`)
      .join('\n');

    return `
You are Prevue's Executive YouTube Content Strategist and Retention Algorithm Engine.
Your task is to analyze the following LIVE YouTube channel data and generate 4 high-conviction, highly authentic, non-generic video blueprints for the creator to film next.

=== CREATOR PROFILE ===
Channel Name: ${channel.channelName} (${channel.handle})
Niche / Category: ${channel.niche}
Subscribers: ${(channel.subscribers || 0).toLocaleString()}
Median views: ${(channel.medianViews || 0).toLocaleString()}
Upload frequency: ${channel.uploadFrequency} / week
Signature Style: ${channel.signatureCreatorStyle}
Signature Hook Style: ${authenticityProfile?.signatureHookStyle}
Retention Vulnerability Area: ${authenticityProfile?.retentionVulnerabilityArea}
Question-to-Praise Authority Ratio: ${authenticityProfile?.questionToPraiseRatio}x

=== TOPIC PERFORMANCE MULTIPLIERS ===
${topicLines}

=== RECENT UPLOADS & HISTORICAL OUTLIERS ===
${videoLines}

=== AUDIENCE DEMAND CLUSTERS (Mined from Comments) ===
${demandClusterLines || '  - No comment demand data available; rely on topic performance multipliers.'}

=== VECTOR-MATCHED HISTORICAL OUTLIERS (pgvector cosine similarity) ===
${vectorOutlierLines || '  - No semantic vector matches available yet; rely on raw view counts for the historical outlier sequel.'}

=== BLUEPRINT SPECIFICATION REQUIREMENTS ===
Generate exactly 4 video blueprints following these distinct strategic angles:
1. Blueprint 1 (Community Demand Hero): Directly solves the #1 most upvoted question or demand cluster from the comments. Cite the commenter and real upvote metrics in the hook.
2. Blueprint 2 (Historical Outlier Sequel): Organic evolution/sequel to the channel's top-performing upload — prefer a vector-matched historical outlier above if one is listed.
3. Blueprint 3 (High-Resonance System Deep-Dive): Long-form architectural/practical breakdown on a high-velocity topic cluster.
4. Blueprint 4 (High-Velocity Short): 45-second contrarian rule breakdown targeting 135%+ completion rate.

=== CRITICAL JSON FORMATTING RULES ===
1. Respond ONLY with a valid RFC-8259 JSON object starting with '{' and ending with '}'.
2. Do NOT output markdown code fences (no \`\`\`json).
3. Do NOT include raw literal linebreaks inside string values; keep every string on a single line.
4. Ensure all double quotes inside string literals are properly escaped (\\").
5. Keep each text field punchy, precise, and concise (1-2 sentences) to guarantee full JSON completion.

=== OUTPUT JSON SCHEMA ===
{
  "blueprints": [
    {
      "id": "bp_gemini_1",
      "title": "Compelling, high-CTR, non-clickbait title",
      "format": "longForm",
      "formatLabel": "Long-Form (12–15 Min)",
      "hookText": "First 5-15 seconds script hook addressing viewer tension and creator DNA",
      "thumbnailConceptLeft": "Visual element for left side of thumbnail",
      "thumbnailConceptRight": "Visual element for right side with proof",
      "thumbnailTag": "2-3 word high-contrast badge",
      "dataProofReason": "Mathematical and historical justification citing actual views, comments, or DVI",
      "predictedMultiplier": 3.4,
      "convictionScore": 9.2,
      "categoryTag": "Topic category",
      "demandEvidenceSummary": "Summary of viewer comments backing this video",
      "creatorAuthenticityProof": "How this matches creator signature style",
      "engagementContext": "Engagement signal driving this recommendation",
      "preEngineeredRetentionAnchors": [
        "0:00 - 0:05: High-tension hook",
        "0:05 - 0:25: Immediate visual proof / thesis statement",
        "0:25 - 4:00: Step-by-step resolution",
        "End: Retention bridge to recommended next video"
      ]
    }
  ]
}
`;
  }

  private generateAlgorithmicBlueprints(
    channel: MinedChannelData,
    vectorOutliers: { title: string; views: number; performance_multiple: number }[] = [],
  ): StructuredBlueprint[] {
    const medianV = channel.medianViews || 18400;
    const topTopic = channel.topicPerformanceMultipliers?.[0]?.topic || 'AI & Developer Workflows';
    const topCluster = channel.audienceInsight?.topDemandClusters?.[0];
    const style = channel.authenticityProfile?.signatureHookStyle || 'Data-backed tension with immediate proof';
    const bestVectorMatch = vectorOutliers[0];

    const blueprints: StructuredBlueprint[] = [];

    if (topCluster) {
      const quote = topCluster.sampleComments?.[0];
      blueprints.push({
        id: 'bp_algo_demand',
        title: `${topCluster.topicKeyword}: The Full Breakdown You Asked For`,
        format: 'longForm',
        formatLabel: 'Long-Form (10–13 Min)',
        hookText: quote
          ? `"${quote.text}" — ${quote.authorDisplayName} isn't the only one asking. Here's the definitive answer.`
          : `Your audience keeps asking about ${topCluster.topicKeyword}. Here's the definitive answer.`,
        thumbnailConceptLeft: 'Viewer question overlay',
        thumbnailConceptRight: 'Verified solution reveal',
        thumbnailTag: 'YOU ASKED',
        dataProofReason: `${topCluster.commentFrequency} viewer requests and ${topCluster.totalUpvotes} upvotes on this exact topic (DVI ${topCluster.demandVelocityIndex}).`,
        predictedMultiplier: 2.2,
        convictionScore: 9.0,
        categoryTag: topCluster.topicKeyword,
        demandEvidenceSummary: `Mined directly from ${topCluster.commentFrequency} audience comments requesting this topic.`,
        creatorAuthenticityProof: `Aligned with signature style: ${style}.`,
        engagementContext: 'Highest Demand Velocity Index cluster this cycle.',
        preEngineeredRetentionAnchors: [
          '0:00 - 0:05: Quote the viewer demand directly',
          '0:05 - 0:25: Immediate visual proof / thesis statement',
          '0:25 - 4:00: Step-by-step resolution without fluff',
          'End: Retention bridge to next topic',
        ],
      });
    }

    blueprints.push({
      id: 'bp_algo_1',
      title: `I Built My Entire Stack With ${topTopic} (The Real Performance)`,
      format: 'longForm',
      formatLabel: 'Long-Form (12–15 Min)',
      hookText: `I gave AI control of my development workflow for 30 days. Most people think it saves 10 hours a week, but what actually happened to our production velocity was completely unexpected...`,
      thumbnailConceptLeft: `Original manual dev bottleneck (Red)`,
      thumbnailConceptRight: `Automated agent pipeline (Green 3.2x speed)`,
      thumbnailTag: `TESTED & BENCHMARKED`,
      dataProofReason: `Topics in ${topTopic} generate ${channel.topicPerformanceMultipliers?.[0]?.multiple || 2.4}× your channel median views (${medianV.toLocaleString()} baseline).`,
      predictedMultiplier: channel.topicPerformanceMultipliers?.[0]?.multiple || 2.4,
      convictionScore: 9.2,
      categoryTag: topTopic,
      demandEvidenceSummary: `Derived from live channel performance metrics across ${channel.recentVideos?.length || 0} recent uploads.`,
      creatorAuthenticityProof: `Aligned with signature style: ${style}.`,
      engagementContext: 'Highest topic performance multiplier this cycle.',
      preEngineeredRetentionAnchors: [
        '0:00 - 0:05: High-tension premise and bold core thesis',
        '0:05 - 0:25: Immediate visual proof / code diff',
        '0:25 - 4:00: Step-by-step resolution without fluff',
        'End: Retention bridge to next tutorial',
      ],
    });

    blueprints.push(
      bestVectorMatch
        ? {
            id: 'bp_algo_2',
            title: `The Sequel to "${bestVectorMatch.title}" (Round 2)`,
            format: 'longForm',
            formatLabel: 'Long-Form (10–13 Min)',
            hookText: `"${bestVectorMatch.title}" outperformed your median by ${bestVectorMatch.performance_multiple.toFixed(1)}x. Here's the organic follow-up your audience is already primed for.`,
            thumbnailConceptLeft: 'Original outlier thumbnail callback',
            thumbnailConceptRight: 'Round 2 escalation reveal',
            thumbnailTag: 'THE SEQUEL',
            dataProofReason: `Semantically matched via pgvector to your top historical outlier at ${bestVectorMatch.performance_multiple.toFixed(1)}x median (${bestVectorMatch.views.toLocaleString()} views).`,
            predictedMultiplier: Math.max(1.4, bestVectorMatch.performance_multiple * 0.75),
            convictionScore: 9.1,
            categoryTag: 'Historical Outlier Sequel',
            demandEvidenceSummary: `Vector-matched semantic sequel to "${bestVectorMatch.title}".`,
            creatorAuthenticityProof: `Aligned with signature style: ${style}.`,
            engagementContext: `Retention vulnerability noted at ${channel.authenticityProfile?.retentionVulnerabilityArea}; anchors below correct for it.`,
            preEngineeredRetentionAnchors: [
              '0:00 - 0:05: Callback to the original outlier\'s premise',
              '0:05 - 0:20: What changed since round 1',
              '0:20 - 3:30: Escalated proof / live demo',
              'End: Call-to-action & related video link',
            ],
          }
        : {
            id: 'bp_algo_2',
            title: `Why 90% of Devs Fail With Autonomous Agents in 2026`,
            format: 'longForm',
            formatLabel: 'Long-Form (10–13 Min)',
            hookText: `If you are still prompting LLMs line-by-line in 2026, you are wasting 80% of your engineering leverage. Here is the single architectural shift we enforce on our team...`,
            thumbnailConceptLeft: `Brittle chat prompting (X)`,
            thumbnailConceptRight: `Event-driven agent workflow (Check)`,
            thumbnailTag: `THE 2026 SHIFT`,
            dataProofReason: `Follow-up to your outlier upload with ${channel.topOutlierMultiplier || 2.1}× view velocity.`,
            predictedMultiplier: 2.1,
            convictionScore: 8.9,
            categoryTag: 'Architecture',
            demandEvidenceSummary: 'Organic sequel to the channel historical top outlier upload.',
            creatorAuthenticityProof: `Aligned with signature style: ${style}.`,
            engagementContext: `Retention vulnerability noted at ${channel.authenticityProfile?.retentionVulnerabilityArea}; anchors below correct for it.`,
            preEngineeredRetentionAnchors: [
              '0:00 - 0:05: Contrarian rule statement',
              '0:05 - 0:20: Side-by-side terminal comparison',
              '0:20 - 3:30: Live refactoring demo',
              'End: Call-to-action & code template link',
            ],
          },
    );

    return blueprints.slice(0, 4);
  }
}
