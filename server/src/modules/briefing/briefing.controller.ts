import { Controller, Post, Body, HttpException, HttpStatus } from '@nestjs/common';
import { BriefingService } from './briefing.service';
import { GenerateBriefingDto } from './dto/generate-briefing.dto';

@Controller('api/briefing')
export class BriefingController {
  constructor(private readonly briefingService: BriefingService) {}

  @Post('generate')
  async generate(@Body() dto: GenerateBriefingDto) {
    try {
      const blueprints = await this.briefingService.generateDailyBriefing(dto.channel);
      return { success: true, blueprints };
    } catch (error: any) {
      throw new HttpException(
        error.message || 'Blueprint generation failed',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
