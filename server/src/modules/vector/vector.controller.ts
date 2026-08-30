import { Controller, Post, Body, HttpException, HttpStatus } from '@nestjs/common';
import { VectorService } from './vector.service';
import { SearchOutliersDto } from './dto/vector-search.dto';

@Controller('api/vector')
export class VectorController {
  constructor(private readonly vectorService: VectorService) {}

  @Post('search-outliers')
  async searchOutliers(@Body() dto: SearchOutliersDto) {
    try {
      const outliers = await this.vectorService.findSemanticallySimilarOutliers(
        dto.creatorId,
        dto.ideaText,
        dto.minMultiplier || 1.4,
      );
      return { success: true, outliers };
    } catch (error: any) {
      throw new HttpException(
        error.message || 'Vector search failed',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Post('demand-clusters')
  async demandClusters(
    @Body('creatorId') creatorId: string,
    @Body('topicText') topicText: string,
  ) {
    try {
      if (!creatorId || !topicText) {
        throw new HttpException(
          'creatorId and topicText are required',
          HttpStatus.BAD_REQUEST,
        );
      }
      const clusters = await this.vectorService.findCommentDemandClusters(
        creatorId,
        topicText,
      );
      return { success: true, clusters };
    } catch (error: any) {
      throw new HttpException(
        error.message || 'Demand search failed',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
