import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DatabaseService } from '../../database/database.service';

@Injectable()
export class VectorService {
  private readonly logger = new Logger(VectorService.name);
  private readonly geminiApiKey: string;

  // Free-tier embedContent quota is ~100 requests/minute. Channel sync fires
  // one embedding call per video plus one per comment concurrently
  // (youtube.controller.ts's ingestVideoAndCommentEmbeddings), which can
  // easily be 100+ calls the instant a sync completes. This queue serializes
  // every embedding call app-wide and spaces them ~700ms apart (~85/min,
  // safely under quota) so bursts degrade to the deterministic fallback
  // gracefully instead of the whole burst failing at once.
  private embeddingQueueTail: Promise<void> = Promise.resolve();
  private lastEmbeddingCallAt = 0;
  private readonly minEmbeddingIntervalMs = 700;

  constructor(
    private configService: ConfigService,
    private databaseService: DatabaseService,
  ) {
    this.geminiApiKey = this.configService.get<string>('geminiApiKey', '');
  }

  private throttleEmbeddingCall(): Promise<void> {
    const scheduled = this.embeddingQueueTail.then(async () => {
      const wait = Math.max(0, this.lastEmbeddingCallAt + this.minEmbeddingIntervalMs - Date.now());
      if (wait > 0) await new Promise((r) => setTimeout(r, wait));
      this.lastEmbeddingCallAt = Date.now();
    });
    this.embeddingQueueTail = scheduled.catch(() => {});
    return scheduled;
  }

  async generateEmbedding(text: string): Promise<number[]> {
    if (!this.geminiApiKey) {
      return this.generateDeterministicPseudoEmbedding(text);
    }

    try {
      await this.throttleEmbeddingCall();
      // text-embedding-004 was retired; gemini-embedding-001 is the current
      // model. It defaults to 3072-dim output, so outputDimensionality trims
      // it (via MRL truncation) to 768 to match the existing vector(768)
      // pgvector columns without a schema migration.
      const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:embedContent?key=${this.geminiApiKey}`;
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: 'models/gemini-embedding-001',
          content: { parts: [{ text }] },
          outputDimensionality: 768,
        }),
        signal: AbortSignal.timeout(15000),
      });

      const data = await res.json();
      if (!res.ok) {
        this.logger.warn(`Gemini embedding API error ${res.status}: ${JSON.stringify(data.error || data)}`);
        return this.generateDeterministicPseudoEmbedding(text);
      }
      if (data.embedding && data.embedding.values) {
        return data.embedding.values;
      }
      return this.generateDeterministicPseudoEmbedding(text);
    } catch (error: any) {
      this.logger.warn(`Gemini embedding fallback: ${error.message}`);
      return this.generateDeterministicPseudoEmbedding(text);
    }
  }

  async findSemanticallySimilarOutliers(
    creatorId: string,
    ideaText: string,
    minMultiplier: number = 1.4,
  ) {
    const queryEmbedding = await this.generateEmbedding(ideaText);
    return this.databaseService.searchOutlierVideos(
      creatorId,
      queryEmbedding,
      minMultiplier,
      5,
    );
  }

  async findCommentDemandClusters(creatorId: string, topicText: string) {
    const queryEmbedding = await this.generateEmbedding(topicText);
    return this.databaseService.searchCommentDemand(creatorId, queryEmbedding, 6);
  }

  private generateDeterministicPseudoEmbedding(text: string): number[] {
    const vector = new Array(768).fill(0);
    const clean = text.toLowerCase();

    for (let i = 0; i < clean.length; i++) {
      const charCode = clean.charCodeAt(i);
      const index = (charCode * 31 + i * 17) % 768;
      vector[index] += Math.sin(charCode + i);
    }

    const norm = Math.sqrt(vector.reduce((sum, val) => sum + val * val, 0)) || 1;
    return vector.map((v) => v / norm);
  }
}
