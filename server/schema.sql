-- =============================================================================
-- PREVUE: Creator Intelligence Database & pgvector Schema
-- PostgreSQL 16+ with pgvector extension for semantic outlier & demand search
-- =============================================================================

-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 0. Users Table
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
    trial_ends_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Pre-Flight Simulations Table
CREATE TABLE IF NOT EXISTS simulations (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) REFERENCES users(id) ON DELETE CASCADE,
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
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 1. Creators Master Table
CREATE TABLE IF NOT EXISTS creators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    youtube_channel_id VARCHAR(64) UNIQUE NOT NULL,
    handle VARCHAR(64) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    avatar_url TEXT,
    banner_url TEXT,
    subscriber_count BIGINT DEFAULT 0,
    total_views BIGINT DEFAULT 0,
    total_videos INT DEFAULT 0,
    upload_frequency NUMERIC(4,2) DEFAULT 1.0, -- e.g. 2.3 uploads/week
    median_views INT DEFAULT 0,
    avg_views INT DEFAULT 0,
    niche VARCHAR(128) DEFAULT 'Technology & Coding',
    signature_hook_style TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Videos Table
CREATE TABLE IF NOT EXISTS videos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID REFERENCES creators(id) ON DELETE CASCADE,
    youtube_video_id VARCHAR(64) UNIQUE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    published_at TIMESTAMPTZ NOT NULL,
    duration_seconds INT DEFAULT 0,
    duration_formatted VARCHAR(16) DEFAULT '10:00',
    views BIGINT DEFAULT 0,
    likes BIGINT DEFAULT 0,
    comments INT DEFAULT 0,
    category VARCHAR(64),
    tags TEXT[] DEFAULT '{}',
    thumbnail_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Video Embeddings Table (pgvector)
-- Uses 768-dimension vectors for Google Gemini text-embedding-004
CREATE TABLE IF NOT EXISTS video_embeddings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    video_id UUID REFERENCES videos(id) ON DELETE CASCADE,
    creator_id UUID REFERENCES creators(id) ON DELETE CASCADE,
    title_embedding vector(768),
    combined_embedding vector(768), -- title + description + tags
    performance_multiple NUMERIC(5,2) DEFAULT 1.0, -- views / creator.median_views
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- HNSW Vector Index for fast Cosine Distance search (<=>)
CREATE INDEX IF NOT EXISTS idx_video_combined_embedding ON video_embeddings 
USING hnsw (combined_embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- 4. Comment Demand Embeddings Table (pgvector)
CREATE TABLE IF NOT EXISTS comment_embeddings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    video_id UUID REFERENCES videos(id) ON DELETE CASCADE,
    creator_id UUID REFERENCES creators(id) ON DELETE CASCADE,
    author_name VARCHAR(128) NOT NULL,
    comment_text TEXT NOT NULL,
    like_count INT DEFAULT 0,
    intent_category VARCHAR(32) DEFAULT 'request', -- request, question, praise, feedback, discussion
    embedding vector(768),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_comment_embedding ON comment_embeddings 
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- 5. Video Topics Taxonomy
CREATE TABLE IF NOT EXISTS video_topics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    video_id UUID REFERENCES videos(id) ON DELETE CASCADE,
    topic VARCHAR(128) NOT NULL,
    category VARCHAR(128),
    subcategory VARCHAR(128),
    confidence NUMERIC(4,3) DEFAULT 1.0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Creator Metrics Snapshot Table
CREATE TABLE IF NOT EXISTS creator_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID REFERENCES creators(id) ON DELETE CASCADE,
    median_views INT NOT NULL,
    avg_views INT NOT NULL,
    median_engagement NUMERIC(5,2), -- (likes + comments) / views * 100
    upload_frequency NUMERIC(4,2),   -- uploads per week
    top_outlier_multiple NUMERIC(4,2), -- e.g. 4.2x
    best_video_length VARCHAR(32) DEFAULT '10–14 min',
    calculated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Content Ideas / Blueprints Table
CREATE TABLE IF NOT EXISTS content_ideas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID REFERENCES creators(id) ON DELETE CASCADE,
    topic VARCHAR(128) NOT NULL,
    title TEXT NOT NULL,
    format VARCHAR(32) DEFAULT 'longForm',
    hook TEXT NOT NULL,
    thumbnail_left TEXT,
    thumbnail_right TEXT,
    thumbnail_tag VARCHAR(64),
    data_proof_reason TEXT,
    predicted_score NUMERIC(3,1) DEFAULT 8.8,
    predicted_multiplier NUMERIC(4,2) DEFAULT 2.4,
    conviction_score NUMERIC(3,1) DEFAULT 9.0,
    embedding vector(768),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- HELPER FUNCTIONS FOR SEMANTIC SEARCH
-- =============================================================================

-- Find historical videos semantically similar to candidate idea performing above median
CREATE OR REPLACE FUNCTION search_outlier_videos(
    p_creator_id UUID,
    p_query_embedding vector(768),
    p_min_multiplier NUMERIC DEFAULT 1.4,
    p_limit INT DEFAULT 5
)
RETURNS TABLE (
    video_id UUID,
    title TEXT,
    views BIGINT,
    published_at TIMESTAMPTZ,
    performance_multiple NUMERIC,
    cosine_similarity NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        v.id AS video_id,
        v.title,
        v.views,
        v.published_at,
        ve.performance_multiple,
        (1.0 - (ve.combined_embedding <=> p_query_embedding))::NUMERIC AS cosine_similarity
    FROM video_embeddings ve
    JOIN videos v ON v.id = ve.video_id
    WHERE ve.creator_id = p_creator_id
      AND ve.performance_multiple >= p_min_multiplier
    ORDER BY ve.combined_embedding <=> p_query_embedding ASC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Find audience comment clusters matching a candidate concept
CREATE OR REPLACE FUNCTION search_comment_demand(
    p_creator_id UUID,
    p_query_embedding vector(768),
    p_limit INT DEFAULT 6
)
RETURNS TABLE (
    comment_id UUID,
    author_name VARCHAR,
    comment_text TEXT,
    like_count INT,
    intent_category VARCHAR,
    semantic_similarity NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ce.id AS comment_id,
        ce.author_name,
        ce.comment_text,
        ce.like_count,
        ce.intent_category,
        (1.0 - (ce.embedding <=> p_query_embedding))::NUMERIC AS semantic_similarity
    FROM comment_embeddings ce
    WHERE ce.creator_id = p_creator_id
      AND (ce.intent_category = 'request' OR ce.intent_category = 'question')
    ORDER BY ce.embedding <=> p_query_embedding ASC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;
