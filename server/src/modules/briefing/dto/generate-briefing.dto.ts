import { IsNotEmpty, IsObject } from 'class-validator';

export class GenerateBriefingDto {
  @IsNotEmpty()
  @IsObject()
  channel: any;
}
