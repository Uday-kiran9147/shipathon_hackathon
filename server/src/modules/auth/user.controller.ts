import { Controller, Get, Post, Delete, Body, Param, Headers, UnauthorizedException } from '@nestjs/common';
import { DatabaseService } from '../../database/database.service';

@Controller('api/v1/user')
export class UserController {
  constructor(private readonly db: DatabaseService) {}

  private extractEmailFromAuthHeader(authHeader?: string): string {
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return 'creator.google@gmail.com';
    }
    try {
      const token = authHeader.replace('Bearer ', '');
      const payload = JSON.parse(Buffer.from(token, 'base64').toString('utf8'));
      return payload.email || 'creator.google@gmail.com';
    } catch {
      return 'creator.google@gmail.com';
    }
  }

  @Get('profile')
  async getProfile(@Headers('authorization') authHeader?: string) {
    const email = this.extractEmailFromAuthHeader(authHeader);
    const user = await this.db.getUserByEmail(email);
    if (!user) {
      throw new UnauthorizedException('User not found.');
    }
    return {
      success: true,
      user: {
        id: user.id,
        email: user.email,
        displayName: user.display_name,
        photoUrl: user.photo_url,
        connectedChannels: user.connected_channels,
        activeChannelHandle: user.active_channel_handle,
        isGuest: user.is_guest,
        isPro: user.is_pro ?? false,
        createdAt: user.created_at,
      },
    };
  }

  @Post('subscription')
  async updateSubscription(
    @Body() body: { isPro: boolean },
    @Headers('authorization') authHeader?: string,
  ) {
    const email = this.extractEmailFromAuthHeader(authHeader);
    const user = await this.db.getUserByEmail(email);
    if (!user) {
      throw new UnauthorizedException('User not found.');
    }

    const updated = await this.db.updateUserProStatus(user.id, body.isPro ?? false);
    return {
      success: true,
      isPro: updated?.is_pro ?? body.isPro ?? false,
    };
  }

  @Post('channels')
  async addChannel(
    @Body() body: { handle: string; isPro?: boolean },
    @Headers('authorization') authHeader?: string,
  ) {
    const email = this.extractEmailFromAuthHeader(authHeader);
    const user = await this.db.getUserByEmail(email);
    if (!user) {
      throw new UnauthorizedException('User not found.');
    }

    const cleanHandle = body.handle.startsWith('@') ? body.handle : `@${body.handle}`;
    const channels = Array.from(new Set([...user.connected_channels, cleanHandle]));

    const updated = await this.db.updateUserChannels(user.id, channels, cleanHandle);

    return {
      success: true,
      channels: updated?.connected_channels || channels,
      activeChannel: cleanHandle,
    };
  }

  @Delete('channels/:handle')
  async removeChannel(
    @Param('handle') handle: string,
    @Headers('authorization') authHeader?: string,
  ) {
    const email = this.extractEmailFromAuthHeader(authHeader);
    const user = await this.db.getUserByEmail(email);
    if (!user) {
      throw new UnauthorizedException('User not found.');
    }

    const cleanHandle = handle.startsWith('@') ? handle : `@${handle}`;
    const channels = user.connected_channels.filter((c) => c.toLowerCase() !== cleanHandle.toLowerCase());
    const newActive = user.active_channel_handle.toLowerCase() === cleanHandle.toLowerCase()
      ? (channels.length > 0 ? channels[0] : '@RevenueCat')
      : user.active_channel_handle;

    const updated = await this.db.updateUserChannels(user.id, channels, newActive);

    return {
      success: true,
      channels: updated?.connected_channels || channels,
      activeChannel: newActive,
    };
  }

  @Post('channels/active')
  async switchActiveChannel(
    @Body() body: { handle: string },
    @Headers('authorization') authHeader?: string,
  ) {
    const email = this.extractEmailFromAuthHeader(authHeader);
    const user = await this.db.getUserByEmail(email);
    if (!user) {
      throw new UnauthorizedException('User not found.');
    }

    const cleanHandle = body.handle.startsWith('@') ? body.handle : `@${body.handle}`;
    const updated = await this.db.updateActiveChannel(user.id, cleanHandle);

    return {
      success: true,
      activeChannel: updated?.active_channel_handle || cleanHandle,
    };
  }
}
