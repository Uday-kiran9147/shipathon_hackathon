import { Controller, Post, Body, HttpException, HttpStatus } from '@nestjs/common';
import { YouTubeService } from './youtube.service';
import { SyncChannelDto } from './dto/sync-channel.dto';
import { DatabaseService } from '../../database/database.service';

@Controller('api/channel')
export class YouTubeController {
  constructor(
    private readonly youtubeService: YouTubeService,
    private readonly databaseService: DatabaseService,
  ) {}

  @Post('sync')
  async sync(@Body() dto: SyncChannelDto) {
    try {
      const channelData = await this.youtubeService.fetchChannelIntelligence(dto.handle);

      // Persist in DB if available
      try {
        await this.databaseService.upsertCreator({
          youtube_channel_id: channelData.channelId,
          handle: channelData.handle,
          title: channelData.title,
          description: channelData.description,
          avatar_url: channelData.avatarUrl,
          subscriber_count: channelData.subscribers,
          total_views: channelData.totalViews,
          total_videos: channelData.totalVideos,
          upload_frequency: channelData.uploadFrequency,
          median_views: channelData.medianViews,
          avg_views: channelData.avgViews,
          niche: channelData.niche,
          signature_hook_style: 'Data-backed tension with immediate code proof',
        });
      } catch (dbErr) {
        // Handled gracefully in DatabaseService
      }

      return { success: true, channel: channelData };
    } catch (error: any) {
      throw new HttpException(
        error.message || 'Channel sync failed',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
