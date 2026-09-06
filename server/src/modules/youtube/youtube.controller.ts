import { Controller, Post, Body, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { YouTubeService } from './youtube.service';
import { SyncChannelDto } from './dto/sync-channel.dto';
import { DatabaseService } from '../../database/database.service';
import { VectorService } from '../vector/vector.service';

@Controller(['api/channel', 'api/v1/channel'])
export class YouTubeController {
  private readonly logger = new Logger(YouTubeController.name);

  constructor(
    private readonly youtubeService: YouTubeService,
    private readonly databaseService: DatabaseService,
    private readonly vectorService: VectorService,
  ) {}

  @Post('sync')
  async sync(@Body() dto: SyncChannelDto) {
    try {
      const channelData = await this.youtubeService.fetchChannelIntelligence(
        dto.handle,
        dto.apiKey,
      );

      // Persist creator + mine video/comment embeddings in DB if available.
      // Best-effort: sync always returns channelData even if DB writes fail.
      try {
        const creator = await this.databaseService.upsertCreator({
          youtube_channel_id: channelData.channelId,
          handle: channelData.handle,
          title: channelData.channelName,
          description: channelData.channelDescription,
          avatar_url: channelData.avatarUrl || '',
          subscriber_count: channelData.subscribers,
          total_views: channelData.totalViews,
          total_videos: channelData.totalVideos,
          upload_frequency: channelData.uploadFrequency,
          median_views: channelData.medianViews,
          avg_views: channelData.avgViews,
          niche: channelData.niche,
          signature_hook_style: channelData.authenticityProfile.signatureHookStyle,
        });

        if (creator?.id) {
          // Fire-and-forget: embedding generation makes one Gemini call per
          // video and per comment, which can take far longer than a request
          // should ever block on. It runs after the response is sent and
          // never affects what `sync` returns to the client.
          this.ingestVideoAndCommentEmbeddings(creator.id, channelData).catch(
            (err) => this.logger.debug(`Background embedding ingestion failed: ${err.message}`),
          );
        }
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

  /// Mine per-video and per-comment embeddings so the Vector module can power
  /// semantic outlier search and comment-demand search for this creator.
  private async ingestVideoAndCommentEmbeddings(
    creatorId: string,
    channelData: Awaited<ReturnType<YouTubeService['fetchChannelIntelligence']>>,
  ) {
    const medianViews = Math.max(1, channelData.medianViews);

    // Videos are embedded concurrently (each with its own comment embeddings
    // run sequentially) rather than one giant sequential chain — this whole
    // method already runs in the background, off the request/response path.
    await Promise.all(
      channelData.recentVideos.map(async (video) => {
        try {
          const savedVideo = await this.databaseService.upsertVideo({
            creator_id: creatorId,
            youtube_video_id: video.id,
            title: video.title,
            description: video.description,
            published_at: new Date(video.publishedAt),
            duration_seconds: 0,
            views: video.views,
            likes: video.likes,
            comments: video.commentCount,
            thumbnail_url: video.thumbnailUrl || '',
          });
          if (!savedVideo?.id) return;

          const combinedText = `${video.title} ${video.description} ${video.tags.join(' ')}`.trim();
          const embedding = await this.vectorService.generateEmbedding(combinedText);
          await this.databaseService.upsertVideoEmbedding({
            creator_id: creatorId,
            video_id: savedVideo.id,
            performance_multiple: parseFloat((video.views / medianViews).toFixed(2)),
            combined_embedding: embedding,
          });

          for (const comment of video.topComments) {
            if (!comment.id) continue;
            const commentEmbedding = await this.vectorService.generateEmbedding(comment.text);
            await this.databaseService.upsertCommentEmbedding({
              creator_id: creatorId,
              video_id: savedVideo.id,
              youtube_comment_id: comment.id,
              author_name: comment.authorDisplayName,
              comment_text: comment.text,
              like_count: comment.likeCount,
              intent_category: comment.intentCategory,
              embedding: commentEmbedding,
            });
          }
        } catch (err: any) {
          this.logger.debug(`Skipping embedding ingestion for video ${video.id}: ${err.message}`);
        }
      }),
    );
  }
}
