import { IsNotEmpty, IsNumber, IsOptional, IsString, IsArray } from 'class-validator';

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

  // Channel intelligence — sent by Flutter from ChannelGraph / CreatorAuthenticityProfile.
  // All optional so existing clients remain compatible.

  @IsOptional()
  @IsString()
  niche?: string;

  @IsOptional()
  @IsString()
  signatureHookStyle?: string;

  @IsOptional()
  @IsArray()
  topDemandClusters?: { topic: string; dvi: number }[];

  @IsOptional()
  @IsArray()
  outlierVideoFormats?: string[];

  @IsOptional()
  @IsNumber()
  engagementVelocity?: number;

  @IsOptional()
  @IsArray()
  topicMultipliers?: { topic: string; multiplier: number }[];
}
