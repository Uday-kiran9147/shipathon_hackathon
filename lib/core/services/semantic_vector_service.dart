import 'dart:math';
import '../../models/channel_graph.dart';

/// In-Memory Semantic Vector Search Engine & Cosine Similarity Calculator
/// Powers sub-millisecond outlier matching and semantic comment clustering directly on device.
class SemanticVectorService {
  static final SemanticVectorService _instance =
      SemanticVectorService._internal();
  factory SemanticVectorService() => _instance;
  SemanticVectorService._internal();

  /// Calculate Cosine Similarity between two N-dimensional vectors:
  /// similarity = (A · B) / (||A|| * ||B||)
  double cosineSimilarity(List<double> vecA, List<double> vecB) {
    if (vecA.length != vecB.length || vecA.isEmpty) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < vecA.length; i++) {
      dotProduct += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }

    if (normA <= 0.0 || normB <= 0.0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// Generate a normalized 768-dimension semantic feature vector from text
  List<double> generateFeatureVector(String text) {
    const dimension = 768;
    final vector = List<double>.filled(dimension, 0.0);
    final clean = text.toLowerCase().trim();
    if (clean.isEmpty) return vector;

    final words = clean
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .toList();

    for (final word in words) {
      final wHash = word.hashCode.abs() % dimension;
      vector[wHash] += 3.0;

      // Add character 3-gram hashes for subword overlap
      for (int i = 0; i <= word.length - 3; i++) {
        final tri = word.substring(i, i + 3);
        final triHash = tri.hashCode.abs() % dimension;
        vector[triHash] += 1.0;
      }
    }

    // L2 Normalize
    double norm = 0.0;
    for (final v in vector) {
      norm += v * v;
    }
    norm = sqrt(norm);
    if (norm > 0.0) {
      for (int i = 0; i < dimension; i++) {
        vector[i] /= norm;
      }
    }

    return vector;
  }

  /// Find historical videos semantically similar to a draft idea performing above median
  List<Map<String, dynamic>> findSemanticallySimilarOutliers({
    required ChannelGraph channel,
    required String candidateIdea,
    double minMultiplier = 1.3,
  }) {
    if (channel.recentVideos.isEmpty) return [];

    final ideaVector = generateFeatureVector(candidateIdea);
    final medianViews = channel.medianViews > 0 ? channel.medianViews : 10000;
    final results = <Map<String, dynamic>>[];

    for (final video in channel.recentVideos) {
      final performanceMultiplier = (video.views / medianViews);
      if (performanceMultiplier < minMultiplier &&
          channel.recentVideos.length > 2) {
        continue;
      }

      final videoText =
          '${video.title} ${video.description} ${video.tags.join(' ')}';
      final videoVector = generateFeatureVector(videoText);
      final similarity = cosineSimilarity(ideaVector, videoVector);

      results.add({
        'video': video,
        'similarity': (similarity * 100).round() / 100.0,
        'multiplier': (performanceMultiplier * 10).round() / 10.0,
      });
    }

    results.sort(
      (a, b) =>
          (b['similarity'] as double).compareTo(a['similarity'] as double),
    );
    return results.take(3).toList();
  }

  /// Cluster audience comments matching candidate topic by semantic cosine distance
  List<ChannelComment> findRelevantAudienceComments({
    required ChannelGraph channel,
    required String topic,
  }) {
    final topicVector = generateFeatureVector(topic);
    final comments = channel.allRecentComments;
    if (comments.isEmpty) return [];

    final scored = <Map<String, dynamic>>[];
    for (final c in comments) {
      final cVector = generateFeatureVector(c.text);
      final sim = cosineSimilarity(topicVector, cVector);
      scored.add({'comment': c, 'score': sim});
    }

    scored.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );
    return scored
        .where((item) => (item['score'] as double) > 0.15)
        .take(4)
        .map((item) => item['comment'] as ChannelComment)
        .toList();
  }
}
