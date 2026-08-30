import { IsNotEmpty, IsString } from 'class-validator';

export class SyncChannelDto {
  @IsNotEmpty()
  @IsString()
  handle: string;
}
