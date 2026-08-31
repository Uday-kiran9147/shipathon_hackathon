# Prevue Backend Server (NestJS 10.x)

Production-grade **NestJS** backend server for **Prevue (YouTube Creator Intelligence & Pre-Flight Simulator)** with PostgreSQL and `pgvector` semantic vector search.

---

## 🚀 Architecture Overview

The backend is built with **NestJS 10.x** modular architecture:
- **`DatabaseModule`**: Global connection pool managing PostgreSQL and `pgvector` extension lifecycle.
- **`HealthModule`**: Endpoint monitoring and service uptime status (`GET /health`).
- **`YouTubeModule`**: Channel intelligence mining, upload metrics, topic multiples, and median view calculations (`POST /api/channel/sync`).
- **`BriefingModule`**: Gemini 3.7 Flash powered Category & Theme Intelligence Daily Blueprint generator (`POST /api/briefing/generate`).
- **`SimulatorModule`**: Pre-Flight Simulator 7-dimension scoring engine, 30s retention hazard timeline, views projection, and 3 prescriptive fixes (`POST /api/simulator/evaluate`).
- **`VectorModule`**: Cosine distance similarity search for outlier videos & audience demand comments (`POST /api/vector/search-outliers`, `POST /api/vector/demand-clusters`).

---

## 🛠️ Quickstart

### 1. Install Dependencies
```bash
cd server
npm install
```

### 2. Start Server (Development with Hot-Reload)
```bash
npm run start:dev
```

### 3. Build & Run for Production
```bash
npm run build
npm run start:prod
```

Server will run at `http://localhost:3000`.

---

## 📡 API Endpoints

- `GET /health` - Server health & framework status
- `POST /api/channel/sync` - Sync YouTube channel metadata & compute median baseline
- `POST /api/briefing/generate` - Category & Theme Intelligence Daily Blueprint generator (Gemini 3.7 Flash)
- `POST /api/simulator/evaluate` - Pre-Flight Simulator 7-dimension scoring & 30s retention hazard scrubber
- `POST /api/vector/search-outliers` - Cosine distance search for historical outlier videos
- `POST /api/vector/demand-clusters` - Semantic audience demand search
