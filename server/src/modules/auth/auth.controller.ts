import { Controller, Post, Body, HttpCode, HttpStatus, Logger } from '@nestjs/common';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { GoogleAuthDto } from './dto/google-auth.dto';

@Controller('api/v1/auth')
export class AuthController {
  private readonly logger = new Logger(AuthController.name);

  constructor(private readonly authService: AuthService) {}

  @Post('register')
  async register(@Body() dto: RegisterDto) {
    this.logger.log(`📥 [POST /api/v1/auth/register] Received registration request: email="${dto.email}", name="${dto.displayName}", handle="${dto.initialHandle}"`);
    const result = await this.authService.register(dto);
    this.logger.log(`✅ [POST /api/v1/auth/register] Successfully registered user: ${result.user.email} (ID: ${result.user.id})`);
    return result;
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() dto: LoginDto) {
    this.logger.log(`📥 [POST /api/v1/auth/login] Received login request: email="${dto.email}"`);
    const result = await this.authService.login(dto);
    this.logger.log(`✅ [POST /api/v1/auth/login] User authenticated: ${result.user.email} (ID: ${result.user.id})`);
    return result;
  }

  @Post('google')
  @HttpCode(HttpStatus.OK)
  async google(@Body() dto: GoogleAuthDto) {
    this.logger.log(`📥 [POST /api/v1/auth/google] Received 1-Tap Google authentication request (Preferred Handle: "${dto.preferredHandle}")`);
    const result = await this.authService.googleAuth(dto);
    this.logger.log(`✅ [POST /api/v1/auth/google] Google user authenticated: ${result.user.email}`);
    return result;
  }
}

