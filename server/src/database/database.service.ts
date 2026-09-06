import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Pool, PoolClient } from 'pg';
import { randomUUID } from 'crypto';

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
  is_pro?: boolean;
  simulations_used_this_month?: number;
  free_simulations_limit?: number;
  trial_ends_at?: Date | null;
  created_at?: Date;
  updated_at?: Date;
}

export interface SimulationRecord {
  id: string;
  user_id: string;
  channel_handle: string;
  title: string;
  draft_script: string;
  format?: string;
  hook_score: number;
  resonance_score: number;
  novelty_score: number;
  topic_momentum_score: number;
  clarity_score: number;
  pacing_score: number;
  creator_fit_score: number;
  projected_views_multiplier: number;
  projected_views: number;
  performance_tier: string;
  hazards: any;
  fixes: any;
  created_at?: Date;
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

export interface VideoEmbeddingRecord {
  id?: string;
  creator_id: string;
  video_id: string;
  performance_multiple: number;
  combined_embedding: number[];
}

export interface CommentEmbeddingRecord {
  id?: string;
  creator_id: string;
  video_id: string;
  youtube_comment_id: string;
  author_name: string;
  comment_text: string;
  like_count: number;
  intent_category: string;
  embedding: number[];
}

export interface BriefingRecord {
  id: string;
  user_id?: string | null;
  channel_handle: string;
  blueprints: any;
  source: 'gemini' | 'algorithmic';
  created_at?: Date;
}

@Injectable()
export class DatabaseService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(DatabaseService.name);
  private pool: Pool;
  private isConnected = false;

  constructor(private configService: ConfigService) {
    const connectionString = this.configService.get<string>('DATABASE_URL');
    this.logger.log(`Connecting to PostgreSQL with connection string: ${connectionString}`);
    const isCloudDb =
      connectionString?.includes('neon.tech') ||
      connectionString?.includes('aws') ||
      connectionString?.includes('sslmode=');

    this.pool = new Pool({
      connectionString,
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 15000,
      ssl: isCloudDb ? { rejectUnauthorized: false } : undefined,
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
    const maxRetries = 3;
    let attempt = 0;

    while (attempt < maxRetries) {
      attempt++;
      try {
        const client = await this.pool.connect();

        // 1. Create Core Tables (Users, Creators, Videos, Simulations)
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
            is_pro BOOLEAN DEFAULT FALSE,
            simulations_used_this_month INT DEFAULT 0,
            free_simulations_limit INT DEFAULT 3,
            trial_ends_at TIMESTAMP WITH TIME ZONE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
          );

          ALTER TABLE users ADD COLUMN IF NOT EXISTS is_pro BOOLEAN DEFAULT FALSE;
          ALTER TABLE users ADD COLUMN IF NOT EXISTS simulations_used_this_month INT DEFAULT 0;
          ALTER TABLE users ADD COLUMN IF NOT EXISTS free_simulations_limit INT DEFAULT 3;
          ALTER TABLE users ADD COLUMN IF NOT EXISTS trial_ends_at TIMESTAMP WITH TIME ZONE;

          CREATE TABLE IF NOT EXISTS simulations (
            id VARCHAR(64) PRIMARY KEY,
            user_id VARCHAR(64),
            channel_handle VARCHAR(100) NOT NULL,
            title TEXT NOT NULL,
            draft_script TEXT NOT NULL,
            format VARCHAR(32) DEFAULT 'longForm',
            hook_score NUMERIC(3,1) NOT NULL,
            resonance_score NUMERIC(3,1) NOT NULL,
            novelty_score NUMERIC(3,1) NOT NULL,
            topic_momentum_score NUMERIC(3,1) NOT NULL,
            clarity_score NUMERIC(3,1) NOT NULL,
            pacing_score NUMERIC(3,1) NOT NULL,
            creator_fit_score NUMERIC(3,1) NOT NULL,
            projected_views_multiplier NUMERIC(4,2) NOT NULL,
            projected_views BIGINT NOT NULL,
            performance_tier VARCHAR(32) NOT NULL,
            hazards JSONB DEFAULT '[]'::jsonb,
            fixes JSONB DEFAULT '[]'::jsonb,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
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

          CREATE TABLE IF NOT EXISTS briefings (
            id VARCHAR(64) PRIMARY KEY,
            user_id VARCHAR(64),
            channel_handle VARCHAR(100) NOT NULL,
            blueprints JSONB DEFAULT '[]'::jsonb,
            source VARCHAR(16) DEFAULT 'algorithmic',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
          );
        `);

        this.isConnected = true;
        this.logger.log('✅ Connected to PostgreSQL: "users", "simulations", "creators", "videos" & "briefings" tables ready.');

        // 2. Optional pgvector check
        try {
          await client.query('CREATE EXTENSION IF NOT EXISTS vector;');
          await client.query(`
            CREATE TABLE IF NOT EXISTS video_embeddings (
              id VARCHAR(64) PRIMARY KEY,
              creator_id VARCHAR(64) NOT NULL,
              video_id VARCHAR(64) NOT NULL,
              performance_multiple NUMERIC(6,2) DEFAULT 1.0,
              combined_embedding vector(768),
              created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            );

            CREATE TABLE IF NOT EXISTS comment_embeddings (
              id VARCHAR(64) PRIMARY KEY,
              creator_id VARCHAR(64) NOT NULL,
              video_id VARCHAR(64),
              youtube_comment_id VARCHAR(64),
              author_name VARCHAR(255),
              comment_text TEXT NOT NULL,
              like_count INTEGER DEFAULT 0,
              intent_category VARCHAR(64) DEFAULT 'general',
              embedding vector(768),
              created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            );

            ALTER TABLE comment_embeddings ADD COLUMN IF NOT EXISTS video_id VARCHAR(64);
            ALTER TABLE comment_embeddings ADD COLUMN IF NOT EXISTS youtube_comment_id VARCHAR(64);

            CREATE UNIQUE INDEX IF NOT EXISTS idx_video_embeddings_video_id ON video_embeddings(video_id);
            DROP INDEX IF EXISTS idx_comment_embeddings_youtube_comment_id;
            CREATE UNIQUE INDEX idx_comment_embeddings_youtube_comment_id
              ON comment_embeddings(youtube_comment_id);
          `);
          this.logger.log('✅ pgvector extension and vector tables enabled for vector similarity.');
        } catch {
          this.logger.debug('Note: pgvector extension not installed on local PostgreSQL (using in-memory cosine fallback for vector queries).');
        }

        client.release();
        return;
      } catch (err: any) {
        if (attempt < maxRetries) {
          this.logger.warn(`Connection attempt ${attempt} failed: ${err.message}. Retrying in 2s...`);
          await new Promise((resolve) => setTimeout(resolve, 2000));
        } else {
          this.isConnected = false;
          this.logger.warn(`⚠️ PostgreSQL unavailable (running in graceful mock/in-memory mode): ${err.message}`);
        }
      }
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
      // `id` is generated here (rather than relying on a DB-side default)
      // because some deployed `creators` tables have no DEFAULT on `id`,
      // which previously made every insert fail with a NOT NULL violation.
      // ON CONFLICT never touches `id`, so an existing row keeps its id.
      const rows = await this.query<CreatorRecord>(
        `INSERT INTO creators (
          id, youtube_channel_id, handle, title, description, avatar_url,
          subscriber_count, total_views, total_videos, upload_frequency,
          median_views, avg_views, niche, signature_hook_style, updated_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, NOW())
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
          creator.id || randomUUID(),
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

  async upsertVideo(video: VideoRecord): Promise<VideoRecord | null> {
    if (!this.isConnected) return null;
    try {
      const id = video.id || randomUUID();
      const rows = await this.query<VideoRecord>(
        `INSERT INTO videos (
          id, creator_id, youtube_video_id, title, description,
          published_at, duration_seconds, views, likes, comments, thumbnail_url
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
        ON CONFLICT (youtube_video_id) DO UPDATE SET
          creator_id = EXCLUDED.creator_id,
          title = EXCLUDED.title,
          description = EXCLUDED.description,
          published_at = EXCLUDED.published_at,
          duration_seconds = EXCLUDED.duration_seconds,
          views = EXCLUDED.views,
          likes = EXCLUDED.likes,
          comments = EXCLUDED.comments,
          thumbnail_url = EXCLUDED.thumbnail_url
        RETURNING *;`,
        [
          id,
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
        ],
      );
      return rows[0] || null;
    } catch (err: any) {
      this.logger.warn(`Failed to upsert video: ${err.message}`);
      return null;
    }
  }

  async upsertVideoEmbedding(record: VideoEmbeddingRecord): Promise<void> {
    if (!this.isConnected || !pgvector) return;
    try {
      await this.query(
        `INSERT INTO video_embeddings (id, creator_id, video_id, performance_multiple, combined_embedding)
        VALUES ($1, $2, $3, $4, $5)
        ON CONFLICT (video_id) DO UPDATE SET
          performance_multiple = EXCLUDED.performance_multiple,
          combined_embedding = EXCLUDED.combined_embedding;`,
        [
          record.id || randomUUID(),
          record.creator_id,
          record.video_id,
          record.performance_multiple,
          pgvector.toSql(record.combined_embedding),
        ],
      );
    } catch (err: any) {
      this.logger.debug(`Skipping video embedding upsert: ${err.message}`);
    }
  }

  async upsertCommentEmbedding(record: CommentEmbeddingRecord): Promise<void> {
    if (!this.isConnected || !pgvector) return;
    try {
      await this.query(
        `INSERT INTO comment_embeddings (
          id, creator_id, video_id, youtube_comment_id, author_name,
          comment_text, like_count, intent_category, embedding
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        ON CONFLICT (youtube_comment_id) DO UPDATE SET
          comment_text = EXCLUDED.comment_text,
          like_count = EXCLUDED.like_count,
          intent_category = EXCLUDED.intent_category,
          embedding = EXCLUDED.embedding;`,
        [
          record.id || randomUUID(),
          record.creator_id,
          record.video_id,
          record.youtube_comment_id,
          record.author_name,
          record.comment_text,
          record.like_count,
          record.intent_category,
          pgvector.toSql(record.embedding),
        ],
      );
    } catch (err: any) {
      this.logger.debug(`Skipping comment embedding upsert: ${err.message}`);
    }
  }

  async saveBriefing(record: BriefingRecord): Promise<BriefingRecord | null> {
    if (!this.isConnected) return record;
    try {
      const rows = await this.query<BriefingRecord>(
        `INSERT INTO briefings (id, user_id, channel_handle, blueprints, source, created_at)
        VALUES ($1, $2, $3, $4, $5, NOW())
        RETURNING *;`,
        [
          record.id,
          record.user_id || null,
          record.channel_handle,
          JSON.stringify(record.blueprints || []),
          record.source,
        ],
      );
      this.logger.log(`💾 [Database Service] Persisted briefing (ID: ${record.id}) for ${record.channel_handle}.`);
      return rows[0] || record;
    } catch (err: any) {
      this.logger.warn(`Failed to save briefing to DB: ${err.message}`);
      return record;
    }
  }

  async getBriefingsByUserId(userId: string, limit: number = 20): Promise<BriefingRecord[]> {
    if (!this.isConnected) return [];
    try {
      return await this.query<BriefingRecord>(
        `SELECT * FROM briefings WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2;`,
        [userId, limit],
      );
    } catch (err: any) {
      this.logger.warn(`Failed to get briefing history: ${err.message}`);
      return [];
    }
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
          connected_channels, active_channel_handle, is_guest, is_pro,
          simulations_used_this_month, free_simulations_limit, trial_ends_at,
          created_at, updated_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, NOW(), NOW())
        ON CONFLICT (email) DO UPDATE SET
          display_name = EXCLUDED.display_name,
          photo_url = EXCLUDED.photo_url,
          connected_channels = EXCLUDED.connected_channels,
          active_channel_handle = EXCLUDED.active_channel_handle,
          is_pro = EXCLUDED.is_pro,
          simulations_used_this_month = COALESCE(users.simulations_used_this_month, EXCLUDED.simulations_used_this_month),
          free_simulations_limit = COALESCE(users.free_simulations_limit, EXCLUDED.free_simulations_limit),
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
          user.is_guest ?? false,
          user.is_pro ?? false,
          user.simulations_used_this_month ?? 0,
          user.free_simulations_limit ?? 3,
          user.trial_ends_at || null,
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

  async updateUserProStatus(userId: string, isPro: boolean): Promise<UserRecord | null> {
    if (!this.isConnected) return null;
    try {
      const rows = await this.query<UserRecord>(
        `UPDATE users SET is_pro = $1, updated_at = NOW() WHERE id = $2 RETURNING *;`,
        [isPro, userId],
      );
      return rows[0] || null;
    } catch (err: any) {
      this.logger.warn(`Failed to update user pro status: ${err.message}`);
      return null;
    }
  }

  async checkAndIncrementSimulationUsage(
    userIdOrEmail: string,
  ): Promise<{
    allowed: boolean;
    isPro: boolean;
    simulationsUsedThisMonth: number;
    freeSimulationsLimit: number;
    simulationsRemaining: number;
  }> {
    if (!this.isConnected) {
      return {
        allowed: true,
        isPro: false,
        simulationsUsedThisMonth: 1,
        freeSimulationsLimit: 3,
        simulationsRemaining: 2,
      };
    }

    try {
      let user: UserRecord | null = null;
      if (userIdOrEmail.includes('@')) {
        user = await this.getUserByEmail(userIdOrEmail);
      } else {
        user = await this.getUserById(userIdOrEmail);
      }

      if (!user) {
        const cleanId = userIdOrEmail.startsWith('usr_')
          ? userIdOrEmail
          : `usr_guest_${Date.now()}`;
        const cleanEmail = userIdOrEmail.includes('@')
          ? userIdOrEmail
          : 'creator@studio.prevue.app';

        const guestUser: UserRecord = {
          id: cleanId,
          email: cleanEmail,
          display_name: 'Guest Creator',
          photo_url: null,
          connected_channels: ['@RevenueCat'],
          active_channel_handle: '@RevenueCat',
          is_guest: true,
          is_pro: false,
          simulations_used_this_month: 0,
          free_simulations_limit: 3,
        };
        user = await this.upsertUser(guestUser);
      }

      const isPro = user?.is_pro ?? false;
      const limit = user?.free_simulations_limit ?? 3;
      const currentUsed = user?.simulations_used_this_month ?? 0;

      if (isPro) {
        return {
          allowed: true,
          isPro: true,
          simulationsUsedThisMonth: currentUsed,
          freeSimulationsLimit: limit,
          simulationsRemaining: 9999,
        };
      }

      if (currentUsed >= limit) {
        this.logger.warn(`🚫 [Free Trial Limit Reached] User ${user?.email} has used ${currentUsed}/${limit} free simulations.`);
        return {
          allowed: false,
          isPro: false,
          simulationsUsedThisMonth: currentUsed,
          freeSimulationsLimit: limit,
          simulationsRemaining: 0,
        };
      }

      // Atomically increment in PostgreSQL database
      const updatedRows = await this.query<UserRecord>(
        `UPDATE users 
         SET simulations_used_this_month = simulations_used_this_month + 1, updated_at = NOW() 
         WHERE id = $1 
         RETURNING *;`,
        [user!.id],
      );
      const updated = updatedRows[0] || user;
      const newUsed = updated.simulations_used_this_month ?? (currentUsed + 1);

      this.logger.log(`📊 [Database Free Trial Counter] User ${user?.email} incremented simulation usage: ${newUsed}/${limit} (Remaining: ${Math.max(0, limit - newUsed)})`);

      return {
        allowed: true,
        isPro: false,
        simulationsUsedThisMonth: newUsed,
        freeSimulationsLimit: limit,
        simulationsRemaining: Math.max(0, limit - newUsed),
      };
    } catch (err: any) {
      this.logger.warn(`Error checking simulation usage in DB: ${err.message}`);
      return {
        allowed: true,
        isPro: false,
        simulationsUsedThisMonth: 1,
        freeSimulationsLimit: 3,
        simulationsRemaining: 2,
      };
    }
  }

  async getSimulationUsage(
    userIdOrEmail: string,
  ): Promise<{
    isPro: boolean;
    simulationsUsedThisMonth: number;
    freeSimulationsLimit: number;
    simulationsRemaining: number;
  }> {
    if (!this.isConnected) {
      return {
        isPro: false,
        simulationsUsedThisMonth: 0,
        freeSimulationsLimit: 3,
        simulationsRemaining: 3,
      };
    }

    try {
      let user: UserRecord | null = null;
      if (userIdOrEmail.includes('@')) {
        user = await this.getUserByEmail(userIdOrEmail);
      } else {
        user = await this.getUserById(userIdOrEmail);
      }

      const isPro = user?.is_pro ?? false;
      const limit = user?.free_simulations_limit ?? 3;
      const currentUsed = user?.simulations_used_this_month ?? 0;

      return {
        isPro,
        simulationsUsedThisMonth: currentUsed,
        freeSimulationsLimit: limit,
        simulationsRemaining: isPro ? 9999 : Math.max(0, limit - currentUsed),
      };
    } catch {
      return {
        isPro: false,
        simulationsUsedThisMonth: 0,
        freeSimulationsLimit: 3,
        simulationsRemaining: 3,
      };
    }
  }

  async saveSimulation(record: SimulationRecord): Promise<SimulationRecord | null> {
    if (!this.isConnected) return record;
    try {
      const rows = await this.query<SimulationRecord>(
        `INSERT INTO simulations (
          id, user_id, channel_handle, title, draft_script, format,
          hook_score, resonance_score, novelty_score, topic_momentum_score,
          clarity_score, pacing_score, creator_fit_score,
          projected_views_multiplier, projected_views, performance_tier,
          hazards, fixes, created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, NOW())
        RETURNING *;`,
        [
          record.id,
          record.user_id || null,
          record.channel_handle,
          record.title,
          record.draft_script,
          record.format || 'longForm',
          record.hook_score,
          record.resonance_score,
          record.novelty_score,
          record.topic_momentum_score,
          record.clarity_score,
          record.pacing_score,
          record.creator_fit_score,
          record.projected_views_multiplier,
          record.projected_views,
          record.performance_tier,
          JSON.stringify(record.hazards || []),
          JSON.stringify(record.fixes || []),
        ],
      );
      this.logger.log(`💾 [Database Service] Persisted simulation "${record.title}" (ID: ${record.id}) in PostgreSQL.`);
      return rows[0] || record;
    } catch (err: any) {
      this.logger.warn(`Failed to save simulation to DB: ${err.message}`);
      return record;
    }
  }

  async getSimulationsByUserId(userId: string, limit: number = 20): Promise<SimulationRecord[]> {
    if (!this.isConnected) return [];
    try {
      return await this.query<SimulationRecord>(
        `SELECT * FROM simulations WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2;`,
        [userId, limit],
      );
    } catch (err: any) {
      this.logger.warn(`Failed to get simulation history: ${err.message}`);
      return [];
    }
  }

  async resetSimulationUsage(userId: string): Promise<UserRecord | null> {
    if (!this.isConnected) return null;
    try {
      const rows = await this.query<UserRecord>(
        `UPDATE users SET simulations_used_this_month = 0, updated_at = NOW() WHERE id = $1 RETURNING *;`,
        [userId],
      );
      return rows[0] || null;
    } catch (err: any) {
      this.logger.warn(`Failed to reset simulation usage: ${err.message}`);
      return null;
    }
  }
}

