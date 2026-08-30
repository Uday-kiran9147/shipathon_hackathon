import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MinedChannelData } from '../youtube/youtube.service';

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
  preEngineeredRetentionAnchors: string[];
}

@Injectable()
export class BriefingService {
  private readonly logger = new Logger(BriefingService.name);
  private readonly apiKey: string;
  private readonly model: string;

  constructor(private configService: ConfigService) {
    this.apiKey = this.configService.get<string>('geminiApiKey', '');
    this.model = this.configService.get<string>('geminiModel', 'gemini-3.7-flash');
  }

  async generateDailyBriefing(channel: MinedChannelData): Promise<StructuredBlueprint[]> {
    if (!this.apiKey) {
      return this.generateAlgorithmicBlueprints(channel);
    }

    try {
      const prompt = this.buildContextualPrompt(channel);
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${this.model}:generateContent?key=${this.apiKey}`;

      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 0.7,
            responseMimeType: 'application/json',
          },
        }),
      });

      const data = await res.json();
      const rawJson = data.candidates?.[0]?.content?.parts?.[0]?.text;
      if (rawJson) {
        const parsed = JSON.parse(rawJson);
        if (parsed.blueprints && Array.isArray(parsed.blueprints)) {
          return parsed.blueprints;
        }
      }
      return this.generateAlgorithmicBlueprints(channel);
    } catch (e: any) {
      this.logger.warn(`Gemini generation fallback: ${e.message}`);
      return this.generateAlgorithmicBlueprints(channel);
    }
  }

  private buildContextualPrompt(channel: MinedChannelData): string {
    const topicLines = (channel.topicMultipliers || [])
      .map((t) => `${t.topic.padEnd(24)} → ${t.multiple}x median`)
      .join('\n');

    const videoLines = (channel.recentVideos || [])
      .slice(0, 4)
      .map((v, i) => `${i + 1}. "${v.title}" (${v.views} views, ${v.likes} likes)`)
      .join('\n');

    return `
You are Prevue's YouTube Creator Intelligence Engine.
Construct 4 highly authentic, domain-native video concepts based on this creator's actual channel graph data:

CREATOR
Subscribers: ${(channel.subscribers || 0).toLocaleString()}
Median views: ${(channel.medianViews || 0).toLocaleString()}
Upload frequency: ${channel.uploadFrequency} / week
Niche: ${channel.niche}

TOPIC PERFORMANCE
${topicLines}

BEST PERFORMING VIDEOS
${videoLines}

TASK
Generate structured concepts that:
1. Fit this creator's existing audience
2. Aren't simple copies
3. Exploit emerging topic patterns
4. Have a strong hook
5. Have plausible performance above median

Respond ONLY with a JSON object strictly matching this schema:
{
  "blueprints": [
    {
      "id": "bp_1",
      "title": "Title with high CTR and tension",
      "format": "longForm",
      "formatLabel": "Long-Form (12–15 Min)",
      "hookText": "First 5-15 seconds script hook with immediate tension",
      "thumbnailConceptLeft": "Visual element for left side",
      "thumbnailConceptRight": "Visual element for right side",
      "thumbnailTag": "2-3 word high contrast tag",
      "dataProofReason": "Why this video will outperform the ${channel.medianViews} median baseline",
      "predictedMultiplier": 2.4,
      "convictionScore": 9.1,
      "categoryTag": "AI Tools",
      "preEngineeredRetentionAnchors": [
        "0:00 - 0:05: High-tension premise",
        "0:05 - 0:25: Immediate visual proof",
        "0:25 - 4:00: Step-by-step breakdown",
        "End: Retention bridge"
      ]
    }
  ]
}
`;
  }

  private generateAlgorithmicBlueprints(channel: MinedChannelData): StructuredBlueprint[] {
    const medianV = channel.medianViews || 18400;
    const topTopic = channel.topicMultipliers?.[0]?.topic || 'AI & Developer Workflows';

    return [
      {
        id: 'bp_algo_1',
        title: `I Built My Entire Stack With ${topTopic} (The Real Performance)`,
        format: 'longForm',
        formatLabel: 'Long-Form (12–15 Min)',
        hookText: `I gave AI control of my development workflow for 30 days. Most people think it saves 10 hours a week, but what actually happened to our production velocity was completely unexpected...`,
        thumbnailConceptLeft: `Original manual dev bottleneck (Red)`,
        thumbnailConceptRight: `Automated agent pipeline (Green 3.2x speed)`,
        thumbnailTag: `TESTED & BENCHMARKED`,
        dataProofReason: `Topics in ${topTopic} generate ${channel.topicMultipliers?.[0]?.multiple || 2.4}× your channel median views (${medianV.toLocaleString()} baseline).`,
        predictedMultiplier: channel.topicMultipliers?.[0]?.multiple || 2.4,
        convictionScore: 9.2,
        categoryTag: topTopic,
        preEngineeredRetentionAnchors: [
          '0:00 - 0:05: High-tension premise and bold core thesis',
          '0:05 - 0:25: Immediate visual proof / code diff',
          '0:25 - 4:00: Step-by-step resolution without fluff',
          'End: Retention bridge to next tutorial',
        ],
      },
      {
        id: 'bp_algo_2',
        title: `Why 90% of Devs Fail With Autonomous Agents in 2026`,
        format: 'longForm',
        formatLabel: 'Long-Form (10–13 Min)',
        hookText: `If you are still prompting LLMs line-by-line in 2026, you are wasting 80% of your engineering leverage. Here is the single architectural shift we enforce on our team...`,
        thumbnailConceptLeft: `Brittle chat prompting (X)`,
        thumbnailConceptRight: `Event-driven agent workflow (Check)`,
        thumbnailTag: `THE 2026 SHIFT`,
        dataProofReason: `Follow-up to your outlier upload with ${channel.outlierMultiplier || 2.1}× view velocity.`,
        predictedMultiplier: 2.1,
        convictionScore: 8.9,
        categoryTag: 'Architecture',
        preEngineeredRetentionAnchors: [
          '0:00 - 0:05: Contrarian rule statement',
          '0:05 - 0:20: Side-by-side terminal comparison',
          '0:20 - 3:30: Live refactoring demo',
          'End: Call-to-action & code template link',
        ],
      },
    ];
  }
}
