import { IsOptional, IsString } from 'class-validator';

export class GoogleAuthDto {
  @IsString()
  @IsOptional()
  idToken?: string;

  @IsString()
  @IsOptional()
  preferredHandle?: string;
}
