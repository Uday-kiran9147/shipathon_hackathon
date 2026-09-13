import { Module } from '@nestjs/common';
import { DatabaseModule } from '../../database/database.module';
import { RevenueCatWebhookController } from './revenuecat-webhook.controller';

@Module({
  imports: [DatabaseModule],
  controllers: [RevenueCatWebhookController],
})
export class WebhooksModule {}
