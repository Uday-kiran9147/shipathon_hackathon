import { Router, Request, Response } from 'express';
import { YouTubeService } from '../services/youtube.service';
import { VectorService } from '../services/vector.service';
import { BlueprintService } from '../services/blueprint.service';
import { SimulatorService } from '../services/simulator.service';
import { dbQueries } from '../db/queries';

const router = Router();
const youtubeService = new YouTubeService();
const vectorService = new VectorService();
const blueprintService = new BlueprintService();
const simulatorService = new SimulatorService();

// 1. Channel Sync & Intelligence Mining
router.post('/channel/sync', async (req: Request, res: Response) => {
  try {
    const { handle } = req.body;
    if (!handle) {
      return res.status(400).json({ error: 'handle is required' });
    }

    const channelData = await youtubeService.fetchChannelIntelligence(handle);
    
    // Store in PostgreSQL if connected
    try {
      await dbQueries.upsertCreator({
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
      console.warn('[DB Upsert Warning] Skipping DB persist in demo mode:', dbErr);
    }

    return res.json({ success: true, channel: channelData });
  } catch (error: any) {
    return res.status(500).json({ error: error.message || 'Channel sync failed' });
  }
});

// 2. Vector Semantic Outlier Search
router.post('/vector/search-outliers', async (req: Request, res: Response) => {
  try {
    const { creatorId, ideaText, minMultiplier } = req.body;
    if (!creatorId || !ideaText) {
      return res.status(400).json({ error: 'creatorId and ideaText are required' });
    }

    const outliers = await vectorService.findSemanticallySimilarOutliers(
      creatorId,
      ideaText,
      minMultiplier || 1.4
    );
    return res.json({ success: true, outliers });
  } catch (error: any) {
    return res.status(500).json({ error: error.message || 'Vector search failed' });
  }
});

// 3. Category & Theme Daily Briefing Generation
router.post('/briefing/generate', async (req: Request, res: Response) => {
  try {
    const { channel } = req.body;
    if (!channel) {
      return res.status(400).json({ error: 'channel graph is required' });
    }

    const blueprints = await blueprintService.generateDailyBriefing(channel);
    return res.json({ success: true, blueprints });
  } catch (error: any) {
    return res.status(500).json({ error: error.message || 'Blueprint generation failed' });
  }
});

// 4. Pre-Flight Simulator Stress-Test Evaluation
router.post('/simulator/evaluate', async (req: Request, res: Response) => {
  try {
    const { creatorId, medianViews, title, script, format } = req.body;
    if (!title || !script) {
      return res.status(400).json({ error: 'title and script are required' });
    }

    const result = simulatorService.evaluateScript({
      creatorId: creatorId || 'default',
      medianViews: medianViews || 18400,
      title,
      script,
      format: format || 'longForm',
    });

    return res.json({ success: true, result });
  } catch (error: any) {
    return res.status(500).json({ error: error.message || 'Simulation evaluation failed' });
  }
});

export default router;
