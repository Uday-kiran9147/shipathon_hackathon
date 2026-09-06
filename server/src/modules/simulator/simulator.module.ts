import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { SimulatorService } from './simulator.service';
import { SimulatorController } from './simulator.controller';

@Module({
  imports: [ConfigModule],
  controllers: [SimulatorController],
  providers: [SimulatorService],
  exports: [SimulatorService],
})
export class SimulatorModule {}
