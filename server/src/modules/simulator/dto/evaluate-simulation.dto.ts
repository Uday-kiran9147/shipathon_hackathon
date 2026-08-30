import { IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';

export class EvaluateSimulationDto {
  @IsOptional()
  @IsString()
  creatorId?: string;

  @IsOptional()
  @IsNumber()
  medianViews?: number;

  @IsNotEmpty()
  @IsString()
  title: string;

  @IsNotEmpty()
  @IsString()
  script: string;

  @IsOptional()
  @IsString()
  format?: 'longForm' | 'short';
}
