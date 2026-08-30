import { ENV } from '../config/env';
import { dbQueries } from '../db/queries';

export class VectorService {
  /**
   * Generate 768-dimension vector embedding using Google Gemini API
   */
  async generateEmbedding(text: string): Promise<number[]> {
    if (!ENV.GEMINI_API_KEY) {
      return this.generateDeterministicPseudoEmbedding(text);
    }

    try {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent?key=${ENV.GEMINI_API_KEY}`;
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
    } catch (error) {
      console.warn('[Vector Service Warning] Gemini embedding failed, using fallback:', error);
      return this.generateDeterministicPseudoEmbedding(text);
    }
  }

  /**
   * Search historical videos semantically similar to a draft idea performing above creator's median
   */
  async findSemanticallySimilarOutliers(creatorId: string, ideaText: string, minMultiplier: number = 1.4) {
    const queryEmbedding = await this.generateEmbedding(ideaText);
    return dbQueries.searchOutlierVideos(creatorId, queryEmbedding, minMultiplier, 5);
  }

  /**
   * Search high-density audience comments demanding this topic
   */
  async findCommentDemandClusters(creatorId: string, topicText: string) {
    const queryEmbedding = await this.generateEmbedding(topicText);
    return dbQueries.searchCommentDemand(creatorId, queryEmbedding, 6);
  }

  /**
   * Fallback deterministic normalized 768-dimension embedding generator
   */
  private generateDeterministicPseudoEmbedding(text: string): number[] {
    const vector = new Array(768).fill(0);
    const clean = text.toLowerCase();
    
    for (let i = 0; i < clean.length; i++) {
      const charCode = clean.charCodeAt(i);
      const index = (charCode * 31 + i * 17) % 768;
      vector[index] += Math.sin(charCode + i);
    }

    // L2 Normalize vector
    const norm = Math.sqrt(vector.reduce((sum, val) => sum + val * val, 0)) || 1;
    return vector.map((v) => v / norm);
  }
}
