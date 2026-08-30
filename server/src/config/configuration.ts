export default () => ({
  port: parseInt(process.env.PORT || '3000', 10),
  databaseUrl: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/prevue_db',
  youtubeApiKey: process.env.YOUTUBE_API_KEY || '',
  geminiApiKey: process.env.GEMINI_API_KEY || '',
  geminiModel: process.env.GEMINI_MODEL || 'gemini-3.7-flash',
  revenueCatSecretKey: process.env.REVENUECAT_SECRET_KEY || '',
});
