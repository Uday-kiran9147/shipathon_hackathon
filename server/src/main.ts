import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
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

  const port = configService.get<number>('port', 3000);
  await app.listen(port, '0.0.0.0');


  console.log(`=======================================================`);
  console.log(`🚀 Prevue NestJS Backend Server running on http://localhost:${port}`);
  console.log(`🤖 AI Engine: Gemini 3.7 Flash`);
  console.log(`📊 Vector DB: PostgreSQL + pgvector`);
  console.log(`=======================================================`);
}
bootstrap();
