import { Injectable, UnauthorizedException, BadRequestException, Logger } from '@nestjs/common';
import { DatabaseService, UserRecord } from '../../database/database.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { GoogleAuthDto } from './dto/google-auth.dto';
import * as crypto from 'crypto';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(private readonly db: DatabaseService) {}


  private hashPassword(password: string): string {
    return crypto.createHash('sha256').update(password).digest('hex');
  }

  private generateToken(user: UserRecord): string {
    const payload = {
      sub: user.id,
      email: user.email,
      iat: Math.floor(Date.now() / 1000),
    };
    return Buffer.from(JSON.stringify(payload)).toString('base64');
  }

  async register(dto: RegisterDto) {
    const existing = await this.db.getUserByEmail(dto.email);
    if (existing) {
      throw new BadRequestException('An account with this email already exists.');
    }

    const cleanHandle = dto.initialHandle
      ? dto.initialHandle.startsWith('@')
        ? dto.initialHandle
        : `@${dto.initialHandle}`
      : '@RevenueCat';

    const newUser: UserRecord = {
      id: `usr_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      email: dto.email.trim().toLowerCase(),
      password_hash: this.hashPassword(dto.password),
      display_name: dto.displayName.trim(),
      photo_url: null,
      connected_channels: [cleanHandle],

      active_channel_handle: cleanHandle,
      is_guest: false,
    };

    this.logger.log(`💾 [AuthService] Writing new user to PostgreSQL "users" table: email="${newUser.email}", handle="${newUser.active_channel_handle}"`);
    const saved = await this.db.upsertUser(newUser);
    this.logger.log(`✅ [AuthService] PostgreSQL row saved successfully for ID="${saved?.id || newUser.id}"`);
    const token = this.generateToken(saved || newUser);

    return {
      success: true,
      token,
      user: {
        id: saved?.id || newUser.id,
        email: saved?.email || newUser.email,
        displayName: saved?.display_name || newUser.display_name,
        photoUrl: saved?.photo_url || null,
        connectedChannels: saved?.connected_channels || newUser.connected_channels,
        activeChannelHandle: saved?.active_channel_handle || newUser.active_channel_handle,
        isGuest: false,
        authToken: token,
        createdAt: saved?.created_at || new Date(),
      },
    };
  }

  async login(dto: LoginDto) {
    this.logger.log(`🔍 [AuthService] Querying PostgreSQL for user: email="${dto.email}"`);
    const user = await this.db.getUserByEmail(dto.email);
    if (!user) {
      this.logger.warn(`❌ [AuthService] User not found in PostgreSQL: "${dto.email}"`);
      throw new UnauthorizedException('Invalid email or password.');
    }

    const hashedInput = this.hashPassword(dto.password);
    if (user.password_hash && user.password_hash !== hashedInput) {
      this.logger.warn(`❌ [AuthService] Password hash mismatch for user: "${dto.email}"`);
      throw new UnauthorizedException('Invalid email or password.');
    }

    this.logger.log(`✅ [AuthService] Password verified in PostgreSQL for: "${dto.email}"`);
    const token = this.generateToken(user);


    return {
      success: true,
      token,
      user: {
        id: user.id,
        email: user.email,
        displayName: user.display_name,
        photoUrl: user.photo_url,
        connectedChannels: user.connected_channels,
        activeChannelHandle: user.active_channel_handle,
        isGuest: user.is_guest,
        authToken: token,
        createdAt: user.created_at || new Date(),
      },
    };
  }

  async googleAuth(dto: GoogleAuthDto) {
    const email = 'creator.google@gmail.com';
    const cleanHandle = dto.preferredHandle
      ? dto.preferredHandle.startsWith('@')
        ? dto.preferredHandle
        : `@${dto.preferredHandle}`
      : '@RevenueCat';

    let user = await this.db.getUserByEmail(email);
    if (!user) {
      user = {
        id: `usr_google_${Date.now()}`,
        email,
        password_hash: null,
        display_name: 'Google Verified Creator',
        photo_url: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
        connected_channels: [cleanHandle],

        active_channel_handle: cleanHandle,
        is_guest: false,
      };
      await this.db.upsertUser(user);
    }

    const token = this.generateToken(user);

    return {
      success: true,
      token,
      user: {
        id: user.id,
        email: user.email,
        displayName: user.display_name,
        photoUrl: user.photo_url,
        connectedChannels: user.connected_channels,
        activeChannelHandle: user.active_channel_handle,
        isGuest: user.is_guest,
        authToken: token,
        createdAt: user.created_at || new Date(),
      },
    };
  }
}
