import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { json, urlencoded, Request, Response, NextFunction } from 'express';
import { AppModule } from './app.module';

async function bootstrap() {
  const logger = new Logger('HTTP');
  const app = await NestFactory.create(AppModule);

  // Raise body limit to handle large channel payloads (50 videos × comments × descriptions)
  app.use(json({ limit: '10mb' }));
  app.use(urlencoded({ extended: true, limit: '10mb' }));

  // Global HTTP Request & Endpoint Logging Middleware
  app.use((req: Request, res: Response, next: NextFunction) => {
    const start = Date.now();
    const method = req.method;
    const url = req.originalUrl || req.url;
    const ip = req.ip || req.socket?.remoteAddress || 'local';

    // Log incoming request
    logger.log(`📥 [REQ] ${method} ${url} | Client: ${ip}`);

    // Safely log payload preview for POST/PUT/PATCH (sanitizing sensitive credentials)
    if (req.body && typeof req.body === 'object' && Object.keys(req.body).length > 0) {
      const sanitized = { ...req.body };
      if (sanitized.password) sanitized.password = '******';
      if (typeof sanitized.idToken === 'string' && sanitized.idToken.length > 15) {
        sanitized.idToken = `${sanitized.idToken.substring(0, 10)}...`;
      }
      logger.log(`📦 [BODY] ${JSON.stringify(sanitized)}`);
    }

    res.on('finish', () => {
      const duration = Date.now() - start;
      const status = res.statusCode;
      const icon = status >= 500 ? '🔴' : status >= 400 ? '🟡' : '🟢';
      logger.log(`${icon} [RES] ${method} ${url} -> ${status} (${duration}ms)`);
    });

    next();
  });

  const configService = app.get(ConfigService);

  // Enable CORS for Flutter client & Web
  app.enableCors({
    origin: '*',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
  });

  // Global DTO Validation Pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: false,
    }),
  );

  const port = configService.get<number>('PORT', 3000);
  const nodeEnv = configService.get<string>('NODE_ENV', 'production');
  const geminiModel = configService.get<string>('GEMINI_MODEL', 'gemini-3.6-flash');
  await app.listen(port, '0.0.0.0');

  console.log(`=======================================================`);
  console.log(`🚀 Prevue NestJS Backend Server running on http://localhost:${port}`);
  console.log(`🌍 Environment: ${nodeEnv.toUpperCase()}`);
  console.log(`🤖 AI Engine: ${geminiModel}`);
  console.log(`📊 Vector DB: PostgreSQL + pgvector`);
  console.log(`📡 API Endpoints Console Logging: ACTIVE`);
  console.log(`=======================================================`);
}
bootstrap();

