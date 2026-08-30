import dotenv from 'dotenv';
dotenv.config();

export const ENV = {
  PORT: process.env.PORT ? parseInt(process.env.PORT, 10) : 3000,
  DATABASE_URL: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/prevue_db',
  YOUTUBE_API_KEY: process.env.YOUTUBE_API_KEY || '',
  GEMINI_API_KEY: process.env.GEMINI_API_KEY || '',
  GEMINI_MODEL: process.env.GEMINI_MODEL || 'gemini-3.7-flash',
  REVENUECAT_SECRET_KEY: process.env.REVENUECAT_SECRET_KEY || '',
};
