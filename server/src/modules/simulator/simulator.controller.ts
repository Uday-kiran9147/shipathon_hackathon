import {
  Controller,
  Post,
  Get,
  Body,
  Headers,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { SimulatorService } from './simulator.service';
import { EvaluateSimulationDto } from './dto/evaluate-simulation.dto';
import { DatabaseService, SimulationRecord } from '../../database/database.service';

@Controller(['api/v1/simulator', 'api/simulator'])
export class SimulatorController {
  private readonly logger = new Logger(SimulatorController.name);

  constructor(
    private readonly simulatorService: SimulatorService,
    private readonly db: DatabaseService,
  ) {}

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

  @Post('run')
  async runSimulation(
    @Body() dto: EvaluateSimulationDto,
    @Headers('authorization') authHeader?: string,
  ) {
    return this.handleSimulationExecution(dto, authHeader);
  }

  @Post('evaluate')
  async evaluate(
    @Body() dto: EvaluateSimulationDto,
    @Headers('authorization') authHeader?: string,
  ) {
    return this.handleSimulationExecution(dto, authHeader);
  }

  private async handleSimulationExecution(
    dto: EvaluateSimulationDto,
    authHeader?: string,
  ) {
    const userIdentifier = this.extractEmailOrId(authHeader);

    // 1. Enforce Free Trial limits in PostgreSQL Database
    const usage = await this.db.checkAndIncrementSimulationUsage(userIdentifier);

    if (!usage.allowed) {
      this.logger.warn(
        `🚫 [Simulator API] Free simulation limit reached for: ${userIdentifier} (${usage.simulationsUsedThisMonth}/${usage.freeSimulationsLimit})`,
      );
      throw new HttpException(
        {
          success: false,
          error: 'PRO_REQUIRED',
          message:
            'Free simulation limit reached (3/3). You have 0 free simulations remaining. Unlock Creator Pro for unlimited pre-flight simulations.',
          simulationsUsedThisMonth: usage.simulationsUsedThisMonth,
          freeSimulationsLimit: usage.freeSimulationsLimit,
          simulationsRemaining: 0,
        },
        HttpStatus.FORBIDDEN,
      );
    }

    try {
      const rawScript = dto.script || dto.draftScript || '';
      const result = this.simulatorService.evaluateScript(dto);

      const simId = `sim_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
      const handle = dto.channelHandle || '@RevenueCat';

      // 2. Persist simulation result in PostgreSQL Database
      const simRecord: SimulationRecord = {
        id: simId,
        user_id: userIdentifier,
        channel_handle: handle,
        title: (dto.title || 'Untitled Draft').trim(),
        draft_script: rawScript,
        format: dto.format || 'longForm',
        hook_score: result.scores.hookStrength,
        resonance_score: result.scores.audienceResonance,
        novelty_score: result.scores.novelty,
        topic_momentum_score: result.scores.topicMomentum,
        clarity_score: result.scores.clarity,
        pacing_score: result.scores.pacing,
        creator_fit_score: result.scores.creatorFit,
        projected_views_multiplier: result.viewsMultiplier,
        projected_views: result.projectedViews,
        performance_tier:
          result.scores.hookStrength >= 8.5
            ? 'topOutlier'
            : result.scores.hookStrength >= 7.0
              ? 'aboveMedian'
              : result.scores.hookStrength >= 5.2
                ? 'averageBaseline'
                : 'highFlopRisk',
        hazards: result.hazards,
        fixes: result.fixes,
        created_at: new Date(),
      };

      await this.db.saveSimulation(simRecord);

      return {
        success: true,
        simulationResult: {
          id: simId,
          title: simRecord.title,
          draftScript: rawScript,
          format: simRecord.format,
          hookScore: simRecord.hook_score,
          resonanceScore: simRecord.resonance_score,
          noveltyScore: simRecord.novelty_score,
          topicMomentumScore: simRecord.topic_momentum_score,
          clarityScore: simRecord.clarity_score,
          pacingScore: simRecord.pacing_score,
          creatorFitScore: simRecord.creator_fit_score,
          projectedViewsMultiplier: simRecord.projected_views_multiplier,
          projectedViews: simRecord.projected_views,
          performanceTier: simRecord.performance_tier,
          hazards: result.hazards,
          fixes: result.fixes,
          createdAt: simRecord.created_at,
        },
        result,
        simulationsUsedThisMonth: usage.simulationsUsedThisMonth,
        freeSimulationsLimit: usage.freeSimulationsLimit,
        simulationsRemaining: usage.simulationsRemaining,
        isPro: usage.isPro,
      };
    } catch (error: any) {
      if (error instanceof HttpException) throw error;
      throw new HttpException(
        error.message || 'Simulation evaluation failed',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Get('usage')
  async getUsage(@Headers('authorization') authHeader?: string) {
    const userIdentifier = this.extractEmailOrId(authHeader);
    const usage = await this.db.getSimulationUsage(userIdentifier);
    return {
      success: true,
      ...usage,
    };
  }

  @Get('history')
  async getHistory(@Headers('authorization') authHeader?: string) {
    const userIdentifier = this.extractEmailOrId(authHeader);
    const history = await this.db.getSimulationsByUserId(userIdentifier, 20);
    return {
      success: true,
      simulations: history,
    };
  }
}
