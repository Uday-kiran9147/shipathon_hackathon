---
name: youtube-creator-intelligence
description: >-
  YouTube Data API v3 integration, semantic topic clustering, and blueprint generation skill.
  Use this skill when modifying YouTube data fetching, channel graph mining,
  comment demand clustering, Gemini API prompt generation, resilient JSON parsing,
  or vector similarity calculations.
---

# YouTube Creator Intelligence & Blueprint Generation Engine

This skill manages the intelligence layer of Prevue, converting raw YouTube Data API v3 metadata and audience telemetry into actionable daily video blueprints and pre-flight retention hazard analysis.

## Architecture Overview

```
YouTube Data API v3 (Channel & Video Mining)
   │
   ▼
Channel Graph Model (Median Views, Demographics, Comment Clusters)
   │
   ▼
Blueprint Generator & Gemini NLP Engine (Topic Matching, Authenticity Profile)
   │
   ▼
4-Tier Blueprint Generation & 0:00–0:30 Retention Hazard Predictor
```

---

## Key Development & Execution Protocols

### 1. YouTube Data API v3 Quota Optimization
- Use batch ID queries (`videos?id=id1,id2,id3&part=snippet,statistics`) instead of individual per-video requests.
- Cache channel data locally in `ChannelProvider` to avoid redundant API hits.
- Provide a responsive `ApiKeyConfigSheet` allowing users to supply their own API key dynamically without restarting the app.

### 2. Comment Demand & Authenticity Mining
- Filter top comments for high upvote-to-question ratios to identify latent audience demand.
- Cluster comments into actionable `CommentDemandCluster` structures with `demandVelocityIndex`.

### 3. Resilient JSON Stream Parsing for LLM Blueprints
When invoking Gemini API for real-time blueprint synthesis:
- The parser (`GeminiService.parseBlueprintsFromJson`) must handle code-fenced markdown (` ```json `), unescaped string newlines, and incomplete truncated streaming payloads without throwing unhandled exceptions.
- Provide fallback blueprints generated deterministically from `BlueprintGeneratorService` if network or quota errors occur.

Refer to the complete [API Safety & Quota Guide](./references/api_safety_and_quotas.md) and [Channel Graph Fixture Example](./examples/channel_graph_fixture.dart).

---

## Safety Guardrails
- ⚠️ **Zero Static Fallbacks for Live Handles**: When an authentic live YouTube handle is supplied, compute subscriber counts, median views, and topic clusters strictly from the API response.
- ⚠️ **Secret Leak Protection**: Never log raw YouTube API keys or Gemini API keys to the console.
- ⚠️ **Defensive Serialization**: Always use `tryParse` and fallback defaults when reading API timestamps, duration strings (`PT12M30S`), or numerical counts.
