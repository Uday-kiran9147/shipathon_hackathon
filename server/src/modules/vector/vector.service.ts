import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DatabaseService } from '../../database/database.service';

@Injectable()
export class VectorService {
  private readonly logger = new Logger(VectorService.name);
  private readonly geminiApiKey: string;

  constructor(
    private configService: ConfigService,
    private databaseService: DatabaseService,
  ) {
    this.geminiApiKey = this.configService.get<string>('geminiApiKey', '');
  }

  async generateEmbedding(text: string): Promise<number[]> {
    if (!this.geminiApiKey) {
      return this.generateDeterministicPseudoEmbedding(text);
    }

    try {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent?key=${this.geminiApiKey}`;
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: 'models/text-embedding-004',
          content: { parts: [{ text }] },
        }),
      });

      const data = await res.json();
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
