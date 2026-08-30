import express from 'express';
import cors from 'cors';
import { ENV } from './config/env';
import apiRouter from './routes/api.routes';

const app = express();

app.use(cors());
app.use(express.json());

// Health Check
app.get('/health', (req, res) => {
  res.json({
    status: 'online',
    service: 'Prevue Creator Intelligence & Simulation Backend',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

// Mount API routes
app.use('/api', apiRouter);

app.listen(ENV.PORT, () => {
  console.log(`=======================================================`);
  console.log(`🚀 Prevue Backend Server running on http://localhost:${ENV.PORT}`);
  console.log(`📊 Vector DB: PostgreSQL + pgvector (${ENV.DATABASE_URL.split('@')[1] || 'localhost'})`);
  console.log(`🤖 AI Engine: Gemini 3.7 Flash (${ENV.GEMINI_MODEL})`);
  console.log(`=======================================================`);
});

export default app;
