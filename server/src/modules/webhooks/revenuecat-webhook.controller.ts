import {
  Controller,
  Post,
  Body,
  Headers,
  HttpCode,
  HttpStatus,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DatabaseService } from '../../database/database.service';

// RevenueCat webhook event types that affect Pro status
const PRO_GRANT_EVENTS = new Set([
  'INITIAL_PURCHASE',
  'RENEWAL',
  'UNCANCELLATION',
  'PRODUCT_CHANGE',
  'TRANSFER',
]);
const PRO_REVOKE_EVENTS = new Set(['EXPIRATION', 'BILLING_ISSUE']);

@Controller('api/v1/webhooks')
export class RevenueCatWebhookController {
  private readonly logger = new Logger(RevenueCatWebhookController.name);

  constructor(
    private readonly db: DatabaseService,
    private readonly config: ConfigService,
  ) {}

  @Post('revenuecat')
  @HttpCode(HttpStatus.OK)
  async handleWebhook(
    @Body() body: Record<string, any>,
    @Headers('authorization') authHeader?: string,
  ): Promise<{ received: boolean }> {
    this.verifySignature(authHeader);

    const event = body?.event as Record<string, any> | undefined;
    if (!event?.type) {
      this.logger.warn('RevenueCat webhook: missing event.type — ignoring');
      return { received: true };
    }

    const eventType: string = event.type;
    this.logger.log(`RevenueCat webhook received: ${eventType}`);

    const isPro = PRO_GRANT_EVENTS.has(eventType)
      ? true
      : PRO_REVOKE_EVENTS.has(eventType)
        ? false
        : null;

    if (isPro === null) {
      // Event type has no effect on Pro status (e.g. CANCELLATION keeps access
      // until EXPIRATION, so we leave is_pro unchanged)
      return { received: true };
    }

    const user = await this.resolveUser(event);
    if (!user) {
      this.logger.warn(
        `RevenueCat webhook [${eventType}]: could not resolve user — app_user_id=${event.app_user_id}`,
      );
      return { received: true };
    }

    await this.db.updateUserProStatus(user.id, isPro);
    this.logger.log(
      `RevenueCat webhook [${eventType}]: updated user ${user.email} isPro=${isPro}`,
    );
    return { received: true };
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  private verifySignature(authHeader?: string): void {
    const secret = this.config.get<string>('REVENUECAT_WEBHOOK_SECRET');
    // Skip verification when the secret is not configured (dev / test)
    if (!secret) return;
    if (!authHeader || authHeader !== secret) {
      throw new UnauthorizedException('Invalid RevenueCat webhook signature');
    }
  }

  private async resolveUser(event: Record<string, any>) {
    // 1. Try the app_user_id set by Purchases.logIn(userId) — most reliable
    const appUserId: string | undefined = event.app_user_id;
    if (appUserId && !appUserId.startsWith('$RCAnonymousID')) {
      const byId = await this.db.getUserById(appUserId).catch(() => null);
      if (byId) return byId;
    }

    // 2. Fall back to $email subscriber attribute set by setUserAttributes
    const emailAttr = event.subscriber_attributes?.['$email']?.value as
      | string
      | undefined;
    if (emailAttr) {
      const byEmail = await this.db.getUserByEmail(emailAttr).catch(() => null);
      if (byEmail) return byEmail;
    }

    return null;
  }
}
