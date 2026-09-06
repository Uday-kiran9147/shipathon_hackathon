import { Controller, Post, Get, Body, Headers, HttpException, HttpStatus } from '@nestjs/common';
import { BriefingService } from './briefing.service';
import { GenerateBriefingDto } from './dto/generate-briefing.dto';
import { DatabaseService } from '../../database/database.service';

@Controller(['api/briefing', 'api/v1/briefing'])
export class BriefingController {
  constructor(
    private readonly briefingService: BriefingService,
    private readonly db: DatabaseService,
  ) {}

  /// Matches SimulatorController/UserController's token → identifier convention
  /// so briefing history lines up with the same user bucket as simulations.
  private extractEmailOrId(authHeader?: string): string {
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return 'creator@studio.prevue.app';
    }
    try {
      const token = authHeader.replace('Bearer ', '');
      const payload = JSON.parse(Buffer.from(token, 'base64').toString('utf8'));
      return payload.email || payload.sub || 'creator@studio.prevue.app';
    } catch {
      return 'creator@studio.prevue.app';
    }
  }

  @Post('generate')
  async generate(
    @Body() dto: GenerateBriefingDto,
    @Headers('authorization') authHeader?: string,
  ) {
    try {
      const creator = await this.db.getCreatorByHandle(dto.channel?.handle || '');
      const blueprints = await this.briefingService.generateDailyBriefing(
        dto.channel,
        creator?.id,
      );

      const userId = this.extractEmailOrId(authHeader);
      const source = blueprints.some((b) => b.id.startsWith('bp_gemini'))
        ? 'gemini'
        : 'algorithmic';

      try {
        await this.db.saveBriefing({
          id: `brief_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
          user_id: userId,
          channel_handle: dto.channel?.handle || 'unknown',
          blueprints,
          source,
        });
      } catch {
        // Persistence is best-effort; the generated blueprints still return.
      }

      return { success: true, blueprints };
    } catch (error: any) {
      throw new HttpException(
        error.message || 'Blueprint generation failed',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Get('history')
  async history(@Headers('authorization') authHeader?: string) {
    const userId = this.extractEmailOrId(authHeader);
    const briefings = await this.db.getBriefingsByUserId(userId, 20);
    return { success: true, briefings };
  }
}
