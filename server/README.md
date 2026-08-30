# Prevue Backend Server

Production Node.js + TypeScript backend server for **Prevue (YouTube Creator Intelligence & Pre-Flight Simulator)** with PostgreSQL and `pgvector` semantic vector search.

---

## 🚀 Quickstart

### 1. Start PostgreSQL with pgvector (Docker)
```bash
docker run -d \
  --name prevue-postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=prevue_db \
  -p 5432:5432 \
  pgvector/pgvector:pg16
```

### 2. Apply Schema
```bash
psql -h localhost -U postgres -d prevue_db -f schema.sql
```

### 3. Install & Start Server
```bash
cd server
npm install
npm run dev
```

Server will run at `http://localhost:3000`.

---

## 📡 API Endpoints

- `GET /health` - Server health check
- `POST /api/channel/sync` - Sync YouTube channel metadata, upload frequency, & topic multiples
- `POST /api/vector/search-outliers` - Cosine distance search for historical outlier videos
- `POST /api/briefing/generate` - Category & Theme Intelligence Daily Blueprint generator (Gemini 3.7 Flash)
- `POST /api/simulator/evaluate` - Pre-Flight Simulator 7-dimension scoring, views projection, & 30s retention hazard timeline
