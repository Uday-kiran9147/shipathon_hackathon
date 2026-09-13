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
import { randomUUID } from 'crypto';
import { DatabaseService } from '../../database/database.service';

// Events that grant Pro access
const PRO_GRANT_EVENTS = new Set([
  'INITIAL_PURCHASE',
  'RENEWAL',
  'UNCANCELLATION',
  'PRODUCT_CHANGE',
  'TRANSFER',
  'NON_RENEWING_PURCHASE',
]);

// Events that revoke Pro access
const PRO_REVOKE_EVENTS = new Set([
  'EXPIRATION',
]);

// Events that flag a billing problem (access kept in grace period, but flagged)
const BILLING_ISSUE_EVENTS = new Set(['BILLING_ISSUE']);

// Events with no immediate change to Pro access
// (CANCELLATION: user still has access until EXPIRATION fires)
const NEUTRAL_EVENTS = new Set(['CANCELLATION', 'REFUND', 'SUBSCRIBER_ALIAS']);

type SubscriptionStatus = 'active' | 'in_trial' | 'cancelled' | 'billing_issue' | 'expired';

function deriveStatus(eventType: string, periodType?: string): SubscriptionStatus {
  if (BILLING_ISSUE_EVENTS.has(eventType)) return 'billing_issue';
  if (PRO_REVOKE_EVENTS.has(eventType)) return 'expired';
  if (eventType === 'CANCELLATION') return 'cancelled';
  if (periodType === 'TRIAL' || periodType === 'INTRO') return 'in_trial';
  return 'active';
}

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
    const eventId: string | undefined = event.id;
    const environment: string = event.environment ?? 'PRODUCTION'; // 'SANDBOX' | 'PRODUCTION'

    this.logger.log(`RevenueCat webhook [${eventType}] env=${environment} id=${eventId}`);

    // ── Idempotency ──────────────────────────────────────────────────────────
    if (eventId) {
      const existing = await this.db.getSubscriptionByEventId(eventId);
      if (existing) {
        this.logger.log(`RevenueCat webhook [${eventType}]: duplicate event_id=${eventId} — skipping`);
        return { received: true };
      }
    }

    // ── Resolve user ─────────────────────────────────────────────────────────
    const user = await this.resolveUser(event);
    if (!user) {
      this.logger.warn(
        `RevenueCat webhook [${eventType}]: could not resolve user — app_user_id=${event.app_user_id}`,
      );
      // Still return 200 so RC doesn't keep retrying an unresolvable event
      return { received: true };
    }

    // ── Determine Pro access impact ──────────────────────────────────────────
    const isPro: boolean | null = PRO_GRANT_EVENTS.has(eventType)
      ? true
      : PRO_REVOKE_EVENTS.has(eventType)
        ? false
        : BILLING_ISSUE_EVENTS.has(eventType)
          ? false  // billing issue revokes access immediately
          : null;  // CANCELLATION, REFUND, etc. — no change

    // ── Persist subscription record ──────────────────────────────────────────
    const shouldPersist = !NEUTRAL_EVENTS.has(eventType) || eventType === 'CANCELLATION';
    if (shouldPersist) {
      const status = deriveStatus(eventType, event.period_type);
      const expiresAt = event.expiration_at_ms
        ? new Date(Number(event.expiration_at_ms))
        : event.expires_date
          ? new Date(event.expires_date)
          : undefined;
      const purchasedAt = event.purchased_at_ms
        ? new Date(Number(event.purchased_at_ms))
        : undefined;

      await this.db.upsertSubscription({
        id: randomUUID(),
        user_id: user.id,
        rc_event_id: eventId || null,
        product_id: event.product_id || null,
        store: event.store || null,
        environment,
        entitlement_id: event.entitlement_id || event.entitlement_ids?.[0] || null,
        period_type: event.period_type || null,
        status,
        purchased_at: purchasedAt || null,
        expires_at: expiresAt || null,
        will_renew: eventType !== 'CANCELLATION' && eventType !== 'EXPIRATION',
        event_type: eventType,
        raw_event: event,
      });
    }

    // ── Update users.is_pro (backward compat) ────────────────────────────────
    if (isPro !== null) {
      await this.db.updateUserProStatus(user.id, isPro);
      this.logger.log(
        `RevenueCat webhook [${eventType}]: user=${user.email} isPro=${isPro} env=${environment}`,
      );
    } else {
      this.logger.log(
        `RevenueCat webhook [${eventType}]: user=${user.email} — no Pro status change`,
      );
    }

    return { received: true };
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

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

    // 2. Fall back to $email subscriber attribute set by setUserAttributes()
    const emailAttr = event.subscriber_attributes?.['$email']?.value as string | undefined;
    if (emailAttr) {
      const byEmail = await this.db.getUserByEmail(emailAttr).catch(() => null);
      if (byEmail) return byEmail;
    }

    return null;
  }
}
