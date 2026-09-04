import { IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';

export class EvaluateSimulationDto {
  @IsOptional()
  @IsString()
  creatorId?: string;

  @IsOptional()
  @IsString()
  channelHandle?: string;

  @IsOptional()
  @IsNumber()
  medianViews?: number;

  @IsNotEmpty()
  @IsString()
  title: string;

  @IsOptional()
  @IsString()
  script?: string;

  @IsOptional()
  @IsString()
  draftScript?: string;

  @IsOptional()
  @IsString()
  format?: 'longForm' | 'short';
}
