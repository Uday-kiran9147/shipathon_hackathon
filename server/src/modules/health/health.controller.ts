import { Controller, Get } from '@nestjs/common';

@Controller()
export class HealthController {
  @Get('health')
  getHealth() {
    return {
      status: 'online',
      service: 'Prevue Creator Intelligence & Simulation Backend',
      framework: 'NestJS 10.x',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
    };
  }
}
