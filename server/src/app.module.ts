import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import configuration from './config/configuration';
import { DatabaseModule } from './database/database.module';
import { HealthModule } from './modules/health/health.module';
import { YouTubeModule } from './modules/youtube/youtube.module';
import { BriefingModule } from './modules/briefing/briefing.module';
import { SimulatorModule } from './modules/simulator/simulator.module';
import { VectorModule } from './modules/vector/vector.module';
import { AuthModule } from './modules/auth/auth.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
      envFilePath: [
        `.env.${process.env.NODE_ENV || 'development'}`,
        '.env.production',
        '.env.local',
        '.env',
        '../.env.production',
        '../.env',
      ],
    }),
    DatabaseModule,
    HealthModule,
    AuthModule,
    YouTubeModule,
    BriefingModule,
    SimulatorModule,
    VectorModule,
  ],
})

export class AppModule {}
