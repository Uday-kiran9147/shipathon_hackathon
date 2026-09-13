/**
 * RevenueCat Webhook Unit Tests
 *
 * To run: install dev deps first
 *   npm install --save-dev @nestjs/testing jest @types/jest ts-jest
 *   npx jest test/revenuecat-webhook.spec.ts
 */
import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { UnauthorizedException } from '@nestjs/common';
import { RevenueCatWebhookController } from '../src/modules/webhooks/revenuecat-webhook.controller';
import { DatabaseService } from '../src/database/database.service';

// ── Minimal mocks ──────────────────────────────────────────────────────────

const mockUser = { id: 'usr_test_123', email: 'test@prevue.app', is_pro: false };

function makeMockDb(overrides: Partial<Record<string, jest.Mock>> = {}) {
  return {
    getUserById: jest.fn().mockResolvedValue(mockUser),
    getUserByEmail: jest.fn().mockResolvedValue(mockUser),
    updateUserProStatus: jest.fn().mockResolvedValue({ ...mockUser }),
    upsertSubscription: jest.fn().mockResolvedValue({}),
    getSubscriptionByEventId: jest.fn().mockResolvedValue(null),
    ...overrides,
  } as unknown as DatabaseService;
}

function makeMockConfig(secret?: string) {
  return {
    get: jest.fn((key: string) =>
      key === 'REVENUECAT_WEBHOOK_SECRET' ? secret : undefined,
    ),
  } as unknown as ConfigService;
}

function buildEvent(overrides: Record<string, any> = {}) {
  return {
    id: 'evt_' + Math.random().toString(36).slice(2),
    type: 'INITIAL_PURCHASE',
    app_user_id: mockUser.id,
    product_id: 'creator_pro_annual',
    store: 'PLAY_STORE',
    environment: 'PRODUCTION',
    period_type: 'NORMAL',
    expiration_at_ms: Date.now() + 30 * 24 * 60 * 60 * 1000,
    ...overrides,
  };
}

async function makeController(db: DatabaseService, config: ConfigService) {
  const module: TestingModule = await Test.createTestingModule({
    controllers: [RevenueCatWebhookController],
    providers: [
      { provide: DatabaseService, useValue: db },
      { provide: ConfigService, useValue: config },
    ],
  }).compile();
  return module.get<RevenueCatWebhookController>(RevenueCatWebhookController);
}

// ── Tests ───────────────────────────────────────────────────────────────────

describe('RevenueCatWebhookController', () => {
  describe('Signature verification', () => {
    it('accepts requests when REVENUECAT_WEBHOOK_SECRET is not configured', async () => {
      const db = makeMockDb();
      const config = makeMockConfig(undefined); // no secret
      const controller = await makeController(db, config);

      const result = await controller.handleWebhook(
        { event: buildEvent() },
        undefined, // no auth header
      );
      expect(result).toEqual({ received: true });
    });

    it('accepts requests with correct Authorization header', async () => {
      const secret = 'my-webhook-secret';
      const db = makeMockDb();
      const config = makeMockConfig(secret);
      const controller = await makeController(db, config);

      const result = await controller.handleWebhook(
        { event: buildEvent() },
        secret,
      );
      expect(result).toEqual({ received: true });
    });

    it('rejects requests with wrong Authorization header', async () => {
      const db = makeMockDb();
      const config = makeMockConfig('correct-secret');
      const controller = await makeController(db, config);

      await expect(
        controller.handleWebhook({ event: buildEvent() }, 'wrong-secret'),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('rejects requests with missing Authorization when secret is configured', async () => {
      const db = makeMockDb();
      const config = makeMockConfig('my-secret');
      const controller = await makeController(db, config);

      await expect(
        controller.handleWebhook({ event: buildEvent() }, undefined),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('Event routing', () => {
    let db: DatabaseService;
    let controller: RevenueCatWebhookController;

    beforeEach(async () => {
      db = makeMockDb();
      controller = await makeController(db, makeMockConfig());
    });

    const PRO_GRANT = ['INITIAL_PURCHASE', 'RENEWAL', 'UNCANCELLATION', 'PRODUCT_CHANGE', 'TRANSFER', 'NON_RENEWING_PURCHASE'];
    const PRO_REVOKE = ['EXPIRATION'];
    const BILLING = ['BILLING_ISSUE'];
    const NEUTRAL = ['CANCELLATION', 'REFUND', 'SUBSCRIBER_ALIAS'];

    it.each(PRO_GRANT)('grants Pro for %s event', async (type) => {
      await controller.handleWebhook({ event: buildEvent({ type }) }, undefined);
      expect(db.updateUserProStatus).toHaveBeenCalledWith(mockUser.id, true);
    });

    it.each(PRO_REVOKE)('revokes Pro for %s event', async (type) => {
      await controller.handleWebhook({ event: buildEvent({ type }) }, undefined);
      expect(db.updateUserProStatus).toHaveBeenCalledWith(mockUser.id, false);
    });

    it.each(BILLING)('revokes Pro for %s event (billing issue)', async (type) => {
      await controller.handleWebhook({ event: buildEvent({ type }) }, undefined);
      expect(db.updateUserProStatus).toHaveBeenCalledWith(mockUser.id, false);
    });

    it.each(NEUTRAL)('does not update Pro status for %s event', async (type) => {
      await controller.handleWebhook({ event: buildEvent({ type }) }, undefined);
      // CANCELLATION persists a subscription record but does NOT call updateUserProStatus
      if (type !== 'CANCELLATION') {
        expect(db.updateUserProStatus).not.toHaveBeenCalled();
      }
    });

    it('returns {received:true} for unknown event types', async () => {
      const result = await controller.handleWebhook(
        { event: buildEvent({ type: 'UNKNOWN_FUTURE_EVENT' }) },
        undefined,
      );
      expect(result).toEqual({ received: true });
      expect(db.updateUserProStatus).not.toHaveBeenCalled();
    });
  });

  describe('Idempotency', () => {
    it('skips processing when event.id was already seen', async () => {
      const eventId = 'evt_duplicate_123';
      const db = makeMockDb({
        getSubscriptionByEventId: jest.fn().mockResolvedValue({
          id: 'sub_existing',
          rc_event_id: eventId,
        }),
      });
      const controller = await makeController(db, makeMockConfig());

      const result = await controller.handleWebhook(
        { event: buildEvent({ id: eventId }) },
        undefined,
      );
      expect(result).toEqual({ received: true });
      expect(db.updateUserProStatus).not.toHaveBeenCalled();
      expect(db.upsertSubscription).not.toHaveBeenCalled();
    });

    it('processes new events that have no matching event.id', async () => {
      const db = makeMockDb({
        getSubscriptionByEventId: jest.fn().mockResolvedValue(null),
      });
      const controller = await makeController(db, makeMockConfig());

      await controller.handleWebhook(
        { event: buildEvent({ id: 'evt_new_123' }) },
        undefined,
      );
      expect(db.updateUserProStatus).toHaveBeenCalled();
    });
  });

  describe('User resolution', () => {
    it('resolves user by app_user_id first', async () => {
      const db = makeMockDb();
      const controller = await makeController(db, makeMockConfig());

      await controller.handleWebhook(
        { event: buildEvent({ app_user_id: mockUser.id }) },
        undefined,
      );
      expect(db.getUserById).toHaveBeenCalledWith(mockUser.id);
    });

    it('falls back to $email subscriber attribute when app_user_id is anonymous', async () => {
      const db = makeMockDb({
        getUserById: jest.fn().mockResolvedValue(null),
        getUserByEmail: jest.fn().mockResolvedValue(mockUser),
      });
      const controller = await makeController(db, makeMockConfig());

      await controller.handleWebhook(
        {
          event: buildEvent({
            app_user_id: '$RCAnonymousID:abc123',
            subscriber_attributes: { $email: { value: 'test@prevue.app' } },
          }),
        },
        undefined,
      );
      expect(db.getUserByEmail).toHaveBeenCalledWith('test@prevue.app');
    });

    it('returns received:true when user cannot be resolved (no retry flood)', async () => {
      const db = makeMockDb({
        getUserById: jest.fn().mockResolvedValue(null),
        getUserByEmail: jest.fn().mockResolvedValue(null),
      });
      const controller = await makeController(db, makeMockConfig());

      const result = await controller.handleWebhook(
        { event: buildEvent({ app_user_id: 'usr_ghost' }) },
        undefined,
      );
      expect(result).toEqual({ received: true });
      expect(db.updateUserProStatus).not.toHaveBeenCalled();
    });
  });

  describe('Subscription record persistence', () => {
    it('stores subscription record for grant events', async () => {
      const db = makeMockDb();
      const controller = await makeController(db, makeMockConfig());

      await controller.handleWebhook(
        { event: buildEvent({ type: 'INITIAL_PURCHASE', product_id: 'creator_pro_annual' }) },
        undefined,
      );

      expect(db.upsertSubscription).toHaveBeenCalledWith(
        expect.objectContaining({
          user_id: mockUser.id,
          status: 'active',
          product_id: 'creator_pro_annual',
          environment: 'PRODUCTION',
        }),
      );
    });

    it('marks status in_trial for TRIAL period_type', async () => {
      const db = makeMockDb();
      const controller = await makeController(db, makeMockConfig());

      await controller.handleWebhook(
        { event: buildEvent({ type: 'INITIAL_PURCHASE', period_type: 'TRIAL' }) },
        undefined,
      );

      expect(db.upsertSubscription).toHaveBeenCalledWith(
        expect.objectContaining({ status: 'in_trial' }),
      );
    });

    it('marks status expired for EXPIRATION event', async () => {
      const db = makeMockDb();
      const controller = await makeController(db, makeMockConfig());

      await controller.handleWebhook(
        { event: buildEvent({ type: 'EXPIRATION' }) },
        undefined,
      );

      expect(db.upsertSubscription).toHaveBeenCalledWith(
        expect.objectContaining({ status: 'expired' }),
      );
    });

    it('marks status billing_issue for BILLING_ISSUE event', async () => {
      const db = makeMockDb();
      const controller = await makeController(db, makeMockConfig());

      await controller.handleWebhook(
        { event: buildEvent({ type: 'BILLING_ISSUE' }) },
        undefined,
      );

      expect(db.upsertSubscription).toHaveBeenCalledWith(
        expect.objectContaining({ status: 'billing_issue' }),
      );
    });

    it('stores sandbox environment tag on SANDBOX events', async () => {
      const db = makeMockDb();
      const controller = await makeController(db, makeMockConfig());

      await controller.handleWebhook(
        { event: buildEvent({ environment: 'SANDBOX' }) },
        undefined,
      );

      expect(db.upsertSubscription).toHaveBeenCalledWith(
        expect.objectContaining({ environment: 'SANDBOX' }),
      );
    });
  });

  describe('Missing / malformed body', () => {
    it('returns received:true and does nothing when event is missing', async () => {
      const db = makeMockDb();
      const controller = await makeController(db, makeMockConfig());

      const result = await controller.handleWebhook({}, undefined);
      expect(result).toEqual({ received: true });
      expect(db.updateUserProStatus).not.toHaveBeenCalled();
    });

    it('returns received:true when event.type is absent', async () => {
      const db = makeMockDb();
      const controller = await makeController(db, makeMockConfig());

      const result = await controller.handleWebhook(
        { event: { id: 'evt_no_type' } },
        undefined,
      );
      expect(result).toEqual({ received: true });
    });
  });
});
