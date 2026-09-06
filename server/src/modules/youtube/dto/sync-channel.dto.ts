import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class SyncChannelDto {
  @IsNotEmpty()
  @IsString()
  handle: string;

  @IsOptional()
  @IsString()
  apiKey?: string;
}
