import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DatabaseService } from '../../../database/database.service';

/**
 * Guard that requires an active Pro subscription before allowing access.
 *
 * Source of truth: the `subscriptions` table (written exclusively by the
 * RevenueCat webhook). Never trusts isPro values sent by the client.
 *
 * Usage:
 *   @UseGuards(RequireProGuard)
 *   @Post('pro-only-endpoint')
 *   async myEndpoint() { ... }
 */
@Injectable()
export class RequireProGuard implements CanActivate {
  private readonly logger = new Logger(RequireProGuard.name);

  constructor(
    private readonly db: DatabaseService,
    private readonly config: ConfigService,
  ) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    const request = ctx.switchToHttp().getRequest<Request>();
    const authHeader = (request.headers as any)['authorization'] as string | undefined;

    const userId = this.extractUserId(authHeader);
    if (!userId) {
      throw new ForbiddenException('Authentication required');
    }

    const environment = this.config.get<string>('NODE_ENV') === 'production'
      ? 'PRODUCTION'
      : 'PRODUCTION'; // always check PRODUCTION entitlements; sandbox never unlocks features

    const hasPro = await this.db.hasActiveEntitlement(userId, environment);
    if (!hasPro) {
      this.logger.warn(`[RequireProGuard] Access denied for userId=${userId}`);
      throw new ForbiddenException('Creator Pro subscription required');
    }

    return true;
  }

  private extractUserId(authHeader?: string): string | null {
    if (!authHeader?.startsWith('Bearer ')) return null;
    try {
      const token = authHeader.replace('Bearer ', '');
      const payload = JSON.parse(Buffer.from(token, 'base64').toString('utf8'));
      return (payload.id || payload.sub || payload.userId) ?? null;
    } catch {
      return null;
    }
  }
}
