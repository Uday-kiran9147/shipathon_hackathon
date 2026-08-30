import { Controller, Post, Body, HttpException, HttpStatus } from '@nestjs/common';
import { SimulatorService } from './simulator.service';
import { EvaluateSimulationDto } from './dto/evaluate-simulation.dto';

@Controller('api/simulator')
export class SimulatorController {
  constructor(private readonly simulatorService: SimulatorService) {}

  @Post('evaluate')
  evaluate(@Body() dto: EvaluateSimulationDto) {
    try {
      const result = this.simulatorService.evaluateScript(dto);
      return { success: true, result };
    } catch (error: any) {
      throw new HttpException(
        error.message || 'Simulation evaluation failed',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
