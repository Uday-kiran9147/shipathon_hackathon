import { IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';

export class SearchOutliersDto {
  @IsNotEmpty()
  @IsString()
  creatorId: string;

  @IsNotEmpty()
  @IsString()
  ideaText: string;

  @IsOptional()
  @IsNumber()
  minMultiplier?: number;
}
