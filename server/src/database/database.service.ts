import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Pool, PoolClient } from 'pg';

let pgvector: any = null;
try {
  pgvector = require('pgvector/pg');
} catch {
  // pgvector not required for basic auth and PostgreSQL operations
}

export interface UserRecord {
  id: string;
  email: string;
  password_hash?: string | null;
  display_name: string;
  photo_url?: string | null;
  connected_channels: string[];
  active_channel_handle: string;
  is_guest: boolean;
  created_at?: Date;
  updated_at?: Date;
}

export interface CreatorRecord {
  id?: string;
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
  id?: string;
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

@Injectable()
export class DatabaseService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(DatabaseService.name);
  private pool: Pool;
  private isConnected = false;

  constructor(private configService: ConfigService) {
    const connectionString = this.configService.get<string>('databaseUrl');
    this.pool = new Pool({
      connectionString,
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });

    this.pool.on('connect', async (client: PoolClient) => {
      try {
        if (pgvector && typeof pgvector.registerType === 'function') {
          await pgvector.registerType(client);
        }
      } catch (err: any) {
        this.logger.debug(`pgvector registration notice: ${err.message}`);
      }
    });
  }

  async onModuleInit() {
    try {
      const client = await this.pool.connect();

      // 1. Create Core Tables (Users, Creators, Videos)
      await client.query(`
        CREATE TABLE IF NOT EXISTS users (
          id VARCHAR(64) PRIMARY KEY,
          email VARCHAR(255) UNIQUE NOT NULL,
          password_hash VARCHAR(255),
          display_name VARCHAR(255) NOT NULL,
          photo_url TEXT,
          connected_channels TEXT[] DEFAULT ARRAY['@RevenueCat'],
          active_channel_handle VARCHAR(100) DEFAULT '@RevenueCat',
          is_guest BOOLEAN DEFAULT FALSE,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        CREATE TABLE IF NOT EXISTS creators (
          id VARCHAR(64) PRIMARY KEY,
          youtube_channel_id VARCHAR(64) UNIQUE NOT NULL,
          handle VARCHAR(100) NOT NULL,
          title VARCHAR(255) NOT NULL,
          description TEXT,
          avatar_url TEXT,
          subscriber_count BIGINT DEFAULT 0,
          total_views BIGINT DEFAULT 0,
          total_videos INTEGER DEFAULT 0,
          upload_frequency NUMERIC(5,2) DEFAULT 0,
          median_views BIGINT DEFAULT 0,
          avg_views BIGINT DEFAULT 0,
          niche VARCHAR(100),
          signature_hook_style TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        CREATE TABLE IF NOT EXISTS videos (
          id VARCHAR(64) PRIMARY KEY,
          creator_id VARCHAR(64),
          youtube_video_id VARCHAR(64) UNIQUE NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          published_at TIMESTAMP WITH TIME ZONE,
          duration_seconds INTEGER DEFAULT 0,
          views BIGINT DEFAULT 0,
          likes BIGINT DEFAULT 0,
          comments BIGINT DEFAULT 0,
          thumbnail_url TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
      `);

      this.isConnected = true;
      this.logger.log('✅ Connected to PostgreSQL: "users", "creators" & "videos" tables ready.');

      // 2. Optional pgvector check
      try {
        await client.query('CREATE EXTENSION IF NOT EXISTS vector;');
        this.logger.log('✅ pgvector extension enabled for vector similarity.');
      } catch {
        this.logger.debug('Note: pgvector extension not installed on local PostgreSQL (using in-memory cosine fallback for vector queries).');
      }

      client.release();
    } catch (err: any) {
      this.isConnected = false;
      this.logger.warn(`⚠️ PostgreSQL unavailable (running in graceful mock/in-memory mode): ${err.message}`);
    }
  }

  async onModuleDestroy() {

    await this.pool.end();
  }

  async query<T = any>(text: string, params?: any[]): Promise<T[]> {
    if (!this.isConnected) {
      return [];
    }
    try {
      const res = await this.pool.query(text, params);
      return res.rows as T[];
    } catch (error: any) {
      this.logger.error(`[Database Query Error] ${error.message}`);
      throw error;
    }
  }

  async upsertCreator(creator: CreatorRecord): Promise<CreatorRecord | null> {
    if (!this.isConnected) return null;
    try {
      const rows = await this.query<CreatorRecord>(
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
        ],
      );
      return rows[0] || null;
    } catch (err: any) {
      this.logger.warn(`Failed to upsert creator: ${err.message}`);
      return null;
    }
  }

  async getCreatorByHandle(handle: string): Promise<CreatorRecord | null> {
    if (!this.isConnected) return null;
    const cleanHandle = handle.startsWith('@') ? handle : `@${handle}`;
    const rows = await this.query<CreatorRecord>(
      `SELECT * FROM creators WHERE LOWER(handle) = LOWER($1) LIMIT 1;`,
      [cleanHandle],
    );
    return rows[0] || null;
  }

  async searchOutlierVideos(
    creatorId: string,
    queryEmbedding: number[],
    minMultiplier: number = 1.4,
    limit: number = 5,
  ) {
    if (!this.isConnected) {
      return [
        {
          video_id: 'v_mock_outlier_1',
          title: 'I Replaced My Entire Dev Stack With AI Agents',
          views: 77280,
          performance_multiple: 4.2,
          cosine_similarity: 0.91,
        },
        {
          video_id: 'v_mock_outlier_2',
          title: 'How I Build Production Apps in 3 Days (Complete Workflow)',
          views: 45100,
          performance_multiple: 2.4,
          cosine_similarity: 0.84,
        },
      ];
    }
    try {
      return await this.query(
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
        [pgvector.toSql(queryEmbedding), creatorId, minMultiplier, limit],
      );
    } catch (err: any) {
      this.logger.warn(`Vector search DB error: ${err.message}`);
      return [];
    }
  }

  async searchCommentDemand(
    creatorId: string,
    queryEmbedding: number[],
    limit: number = 6,
  ) {
    if (!this.isConnected) return [];
    try {
      return await this.query(
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
        [pgvector.toSql(queryEmbedding), creatorId, limit],
      );
    } catch (err: any) {
      this.logger.warn(`Comment search DB error: ${err.message}`);
      return [];
    }
  }

  async upsertUser(user: UserRecord): Promise<UserRecord | null> {

    if (!this.isConnected) return user;
    try {
      const rows = await this.query<UserRecord>(
        `INSERT INTO users (
          id, email, password_hash, display_name, photo_url,
          connected_channels, active_channel_handle, is_guest, created_at, updated_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW())
        ON CONFLICT (email) DO UPDATE SET
          display_name = EXCLUDED.display_name,
          photo_url = EXCLUDED.photo_url,
          connected_channels = EXCLUDED.connected_channels,
          active_channel_handle = EXCLUDED.active_channel_handle,
          updated_at = NOW()
        RETURNING *;`,
        [
          user.id,
          user.email,
          user.password_hash || null,
          user.display_name,
          user.photo_url || null,
          user.connected_channels,
          user.active_channel_handle,
          user.is_guest,
        ],
      );
      return rows[0] || null;
    } catch (err: any) {
      this.logger.warn(`Failed to upsert user: ${err.message}`);
      return user;
    }
  }

  async getUserByEmail(email: string): Promise<UserRecord | null> {
    if (!this.isConnected) return null;
    try {
      const rows = await this.query<UserRecord>(
        `SELECT * FROM users WHERE LOWER(email) = LOWER($1) LIMIT 1;`,
        [email.trim()],
      );
      return rows[0] || null;
    } catch (err: any) {
      this.logger.warn(`Failed to get user by email: ${err.message}`);
      return null;
    }
  }

  async getUserById(id: string): Promise<UserRecord | null> {
    if (!this.isConnected) return null;
    try {
      const rows = await this.query<UserRecord>(
        `SELECT * FROM users WHERE id = $1 LIMIT 1;`,
        [id],
      );
      return rows[0] || null;
    } catch (err: any) {
      this.logger.warn(`Failed to get user by id: ${err.message}`);
      return null;
    }
  }

  async updateUserChannels(
    userId: string,
    channels: string[],
    activeHandle?: string,
  ): Promise<UserRecord | null> {
    if (!this.isConnected) return null;
    try {
      const rows = await this.query<UserRecord>(
        `UPDATE users SET 
          connected_channels = $1,
          active_channel_handle = COALESCE($2, active_channel_handle),
          updated_at = NOW()
        WHERE id = $3
        RETURNING *;`,
        [channels, activeHandle || null, userId],
      );
      return rows[0] || null;
    } catch (err: any) {
      this.logger.warn(`Failed to update user channels: ${err.message}`);
      return null;
    }
  }

  async updateActiveChannel(userId: string, handle: string): Promise<UserRecord | null> {
    if (!this.isConnected) return null;
    try {
      const rows = await this.query<UserRecord>(
        `UPDATE users SET active_channel_handle = $1, updated_at = NOW() WHERE id = $2 RETURNING *;`,
        [handle, userId],
      );
      return rows[0] || null;
    } catch (err: any) {
      this.logger.warn(`Failed to update active channel: ${err.message}`);
      return null;
    }
  }
}

