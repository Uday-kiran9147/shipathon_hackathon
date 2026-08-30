import { query } from './client';
import pgvector from 'pgvector/pg';

export interface CreatorRecord {
  id: string;
  youtube_channel_id: string;
  handle: string;
  title: string;
  description: string;
  avatar_url: string;
  subscriber_count: number;
  total_views: number;
  total_videos: number;
  upload_frequency: number;
  median_views: number;
  avg_views: number;
  niche: string;
  signature_hook_style: string;
}

export interface VideoRecord {
  id: string;
  creator_id: string;
  youtube_video_id: string;
  title: string;
  description: string;
  published_at: Date;
  duration_seconds: number;
  views: number;
  likes: number;
  comments: number;
  thumbnail_url: string;
}

export const dbQueries = {
  // Upsert Creator Record
  async upsertCreator(creator: Omit<CreatorRecord, 'id'>): Promise<CreatorRecord> {
    const rows = await query<CreatorRecord>(
      `INSERT INTO creators (
        youtube_channel_id, handle, title, description, avatar_url,
        subscriber_count, total_views, total_videos, upload_frequency,
        median_views, avg_views, niche, signature_hook_style, updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, NOW())
      ON CONFLICT (youtube_channel_id) DO UPDATE SET
        handle = EXCLUDED.handle,
        title = EXCLUDED.title,
        description = EXCLUDED.description,
        avatar_url = EXCLUDED.avatar_url,
        subscriber_count = EXCLUDED.subscriber_count,
        total_views = EXCLUDED.total_views,
        total_videos = EXCLUDED.total_videos,
        upload_frequency = EXCLUDED.upload_frequency,
        median_views = EXCLUDED.median_views,
        avg_views = EXCLUDED.avg_views,
        niche = EXCLUDED.niche,
        signature_hook_style = EXCLUDED.signature_hook_style,
        updated_at = NOW()
      RETURNING *;`,
      [
        creator.youtube_channel_id,
        creator.handle,
        creator.title,
        creator.description,
        creator.avatar_url,
        creator.subscriber_count,
        creator.total_views,
        creator.total_videos,
        creator.upload_frequency,
        creator.median_views,
        creator.avg_views,
        creator.niche,
        creator.signature_hook_style,
      ]
    );
    return rows[0];
  },

  // Find Creator by Handle
  async getCreatorByHandle(handle: string): Promise<CreatorRecord | null> {
    const cleanHandle = handle.startsWith('@') ? handle : `@${handle}`;
    const rows = await query<CreatorRecord>(
      `SELECT * FROM creators WHERE LOWER(handle) = LOWER($1) LIMIT 1;`,
      [cleanHandle]
    );
    return rows[0] || null;
  },

  // Upsert Video Record
  async upsertVideo(video: Omit<VideoRecord, 'id'>): Promise<VideoRecord> {
    const rows = await query<VideoRecord>(
      `INSERT INTO videos (
        creator_id, youtube_video_id, title, description, published_at,
        duration_seconds, views, likes, comments, thumbnail_url
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      ON CONFLICT (youtube_video_id) DO UPDATE SET
        title = EXCLUDED.title,
        description = EXCLUDED.description,
        views = EXCLUDED.views,
        likes = EXCLUDED.likes,
        comments = EXCLUDED.comments,
        thumbnail_url = EXCLUDED.thumbnail_url
      RETURNING *;`,
      [
        video.creator_id,
        video.youtube_video_id,
        video.title,
        video.description,
        video.published_at,
        video.duration_seconds,
        video.views,
        video.likes,
        video.comments,
        video.thumbnail_url,
      ]
    );
    return rows[0];
  },

  // Upsert Video Embedding Vector
  async upsertVideoEmbedding(
    videoId: string,
    creatorId: string,
    embedding: number[],
    performanceMultiple: number
  ) {
    await query(
      `INSERT INTO video_embeddings (
        video_id, creator_id, combined_embedding, performance_multiple
      ) VALUES ($1, $2, $3, $4)
      ON CONFLICT DO NOTHING;`,
      [videoId, creatorId, pgvector.toSql(embedding), performanceMultiple]
    );
  },

  // Search Historical Outlier Videos Semantically
  async searchOutlierVideos(
    creatorId: string,
    queryEmbedding: number[],
    minMultiplier: number = 1.4,
    limit: number = 5
  ) {
    return query(
      `SELECT 
        v.id AS video_id,
        v.title,
        v.views,
        v.published_at,
        ve.performance_multiple,
        (1.0 - (ve.combined_embedding <=> $1))::NUMERIC AS cosine_similarity
      FROM video_embeddings ve
      JOIN videos v ON v.id = ve.video_id
      WHERE ve.creator_id = $2
        AND ve.performance_multiple >= $3
      ORDER BY ve.combined_embedding <=> $1 ASC
      LIMIT $4;`,
      [pgvector.toSql(queryEmbedding), creatorId, minMultiplier, limit]
    );
  },

  // Search Comment Demand Semantically
  async searchCommentDemand(
    creatorId: string,
    queryEmbedding: number[],
    limit: number = 6
  ) {
    return query(
      `SELECT 
        ce.id AS comment_id,
        ce.author_name,
        ce.comment_text,
        ce.like_count,
        ce.intent_category,
        (1.0 - (ce.embedding <=> $1))::NUMERIC AS semantic_similarity
      FROM comment_embeddings ce
      WHERE ce.creator_id = $2
        AND (ce.intent_category = 'request' OR ce.intent_category = 'question')
      ORDER BY ce.embedding <=> $1 ASC
      LIMIT $3;`,
      [pgvector.toSql(queryEmbedding), creatorId, limit]
    );
  },
};
