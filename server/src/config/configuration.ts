export default () => ({
  nodeEnv: process.env.NODE_ENV || 'development',
  NODE_ENV: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000', 10),
  PORT: parseInt(process.env.PORT || '3000', 10),
  databaseUrl: process.env.DATABASE_URL || '',
  DATABASE_URL: process.env.DATABASE_URL || '',
  youtubeApiKey:
    process.env.YOUTUBE_API_KEY || process.env.YOUTUBE_DATA_API_KEY || '',
  YOUTUBE_API_KEY:
    process.env.YOUTUBE_API_KEY || process.env.YOUTUBE_DATA_API_KEY || '',
  geminiApiKey: process.env.GEMINI_API_KEY || '',
  GEMINI_API_KEY: process.env.GEMINI_API_KEY || '',
  geminiModel: process.env.GEMINI_MODEL || 'gemini-3.7-flash',
  GEMINI_MODEL: process.env.GEMINI_MODEL || 'gemini-3.7-flash',
  revenueCatSecretKey: process.env.REVENUECAT_SECRET_KEY || '',
  REVENUECAT_SECRET_KEY: process.env.REVENUECAT_SECRET_KEY || '',
});
