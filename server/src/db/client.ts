import { Pool } from 'pg';
import { ENV } from '../config/env';
import pgvector from 'pgvector/pg';

const isCloudDb =
  ENV.DATABASE_URL?.includes('neon.tech') ||
  ENV.DATABASE_URL?.includes('aws') ||
  ENV.DATABASE_URL?.includes('sslmode=');

export const pool = new Pool({
  connectionString: ENV.DATABASE_URL,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 15000,
  ssl: isCloudDb ? { rejectUnauthorized: false } : undefined,
});

pool.on('connect', async (client) => {
  await pgvector.registerType(client);
});

export async function query<T = any>(text: string, params?: any[]): Promise<T[]> {
  try {
    const res = await pool.query(text, params);
    return res.rows as T[];
  } catch (error) {
    console.error('[Database Query Error]', error);
    throw error;
  }
}
