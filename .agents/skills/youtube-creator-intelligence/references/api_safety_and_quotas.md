# YouTube Data API v3 Safety & Quota Reference

## 1. Quota Cost Accounting

| Endpoint | Standard Quota Cost | Prevue Optimization Strategy |
| :--- | :--- | :--- |
| `channels.list(forHandle=...)` | 1 unit | Fetch once per handle search; cache in Provider |
| `search.list` | 100 units | ⚠️ **AVOID**. Use `channels.list` + `playlistItems` or direct `videos.list` |
| `playlistItems.list(uploads)` | 1 unit | Efficient 10-video batch mining |
| `videos.list(part=snippet,stats)` | 1 unit per 50 videos | Batch query video statistics in a single call |
| `commentThreads.list` | 1 unit | Fetch top 20 comments only for relevant uploads |

---

## 2. Secrets & Environment Handling
- All keys must be declared in `.env` (`YOUTUBE_API_KEY`, `GEMINI_API_KEY`).
- `.env` must remain in `.gitignore`.
- Fallback to offline mock channels (`@Telusko`, `@SrimanKotaru`, `@MrBeast`) if no API key is detected.

---

## 3. NLP & Vector Embeddings
- `SemanticVectorService` generates deterministic 768-dimensional mock vectors when offline.
- Cosine similarity between topic and creator clusters must score between `0.0` and `1.0`.
