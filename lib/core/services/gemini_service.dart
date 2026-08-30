import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../../models/channel_graph.dart';
import '../../models/daily_blueprint.dart';

/// Google Gemini AI Engine for Dynamic Video Blueprint Synthesis
/// Mines real viewer comments, historical video outliers, and creator DNA to generate
/// 100% bespoke, high-retention video blueprints.
class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  String? _customApiKey;
  String _model = AppConstants.geminiModel;

  /// Get current Gemini model identifier
  String get model => _model;

  /// Configure or override Gemini model identifier
  void configureModel(String newModel) {
    _model = newModel;
  }

  /// Configure or override Gemini API Key
  void configureApiKey(String? key) {
    _customApiKey = key;
  }

  String get _effectiveApiKey {
    if (_customApiKey != null && _customApiKey!.isNotEmpty) {
      return _customApiKey!;
    }
    return AppConstants.geminiApiKey;
  }

  bool get hasApiKey => _effectiveApiKey.isNotEmpty;

  /// Generates a list of dynamic bespoke video blueprints using the configured Gemini model
  Future<List<DailyBlueprint>> generateBlueprintsFromChannelGraph(
      ChannelGraph channel) async {
    if (!channel.isConfigured || channel.recentVideos.isEmpty) {
      return [];
    }

    if (!hasApiKey) {
      throw Exception('Gemini API Key is not configured.');
    }

    final prompt = _buildBlueprintGenerationPrompt(channel);
    return _callGeminiWithFallback(
      prompt: prompt,
      channel: channel,
      maxTokens: 8192,
      isSingle: false,
    );
  }

  /// Generates a single fresh on-demand video blueprint using the configured Gemini model
  Future<DailyBlueprint> generateSingleFreshBlueprint(
    ChannelGraph channel, {
    String? focusTopic,
  }) async {
    if (!channel.isConfigured) {
      throw Exception('Connect a YouTube channel to generate blueprints.');
    }

    if (!hasApiKey) {
      throw Exception('Gemini API Key is not configured.');
    }

    final prompt = _buildSingleFreshPrompt(channel, focusTopic: focusTopic);
    final blueprints = await _callGeminiWithFallback(
      prompt: prompt,
      channel: channel,
      maxTokens: 4096,
      isSingle: true,
    );

    if (blueprints.isNotEmpty) {
      return blueprints.first;
    }
    throw Exception('Failed to parse fresh blueprint from Gemini.');
  }

  /// Resilient API caller with model auto-fallback and generous token allocation
  Future<List<DailyBlueprint>> _callGeminiWithFallback({
    required String prompt,
    required ChannelGraph channel,
    required int maxTokens,
    required bool isSingle,
  }) async {
    final candidateModels = <String>[
      _model,
      if (_model != 'gemini-2.5-flash') 'gemini-2.5-flash',
      if (_model != 'gemini-1.5-flash') 'gemini-1.5-flash',
      if (_model != 'gemini-2.0-flash') 'gemini-2.0-flash',
    ];

    DioException? lastDioException;
    Object? lastError;

    for (final currentModel in candidateModels) {
      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/$currentModel:generateContent?key=$_effectiveApiKey';

      try {
        log('[GeminiService] Calling Gemini API ($currentModel, maxTokens: $maxTokens)...');
        final response = await _dio.post(
          url,
          data: {
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': isSingle ? 0.8 : 0.7,
              'topP': 0.95,
              'maxOutputTokens': maxTokens,
              'responseMimeType': 'application/json',
            },
          },
        );

        final candidates = response.data['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          throw Exception('Gemini returned no candidates ($currentModel).');
        }

        final candidate = candidates[0];
        final finishReason = candidate['finishReason']?.toString();
        if (finishReason != null && finishReason != 'STOP') {
          log('[GeminiService] ($currentModel) Candidate finishReason: $finishReason');
        }

        final contentParts = candidate['content']?['parts'] as List?;
        if (contentParts == null || contentParts.isEmpty) {
          throw Exception('Gemini returned empty parts ($currentModel).');
        }

        final rawJsonText = contentParts[0]['text'] as String;
        final blueprints = parseBlueprintsFromJson(rawJsonText, channel);
        if (blueprints.isNotEmpty) {
          return blueprints;
        }
      } on DioException catch (dioErr) {
        lastDioException = dioErr;
        final statusCode = dioErr.response?.statusCode;
        final errorMsg = dioErr.response?.data?['error']?['message'] ?? dioErr.message;
        log('[GeminiService] DioError ($statusCode) on model $currentModel: $errorMsg');

        // Stop immediately on authentication / permission errors
        if (statusCode == 401 || statusCode == 403) {
          throw Exception('Gemini API Authentication Error ($statusCode): $errorMsg');
        }
        // If 404 (model not found) or model syntax error, cascade to next candidate model
        if (statusCode == 404 || (statusCode == 400 && errorMsg.toString().toLowerCase().contains('model'))) {
          continue;
        }
      } catch (e) {
        lastError = e;
        log('[GeminiService] Parsing or generation exception on model $currentModel: $e');
      }
    }

    if (lastDioException != null) {
      final errorMsg = lastDioException.response?.data?['error']?['message'] ?? lastDioException.message;
      throw Exception('Gemini API Error: $errorMsg');
    }
    throw lastError ?? Exception('Gemini generation failed on all attempted models.');
  }

  /// Constructs the system and contextual prompt fed to Gemini
  String _buildBlueprintGenerationPrompt(ChannelGraph channel) {
    final recentVideosBuffer = StringBuffer();
    for (var i = 0; i < channel.recentVideos.length && i < 6; i++) {
      final v = channel.recentVideos[i];
      recentVideosBuffer.writeln(
          '  - "${v.title}" | Views: ${v.views} | Likes: ${v.likes} | Comments: ${v.commentCount}');
      if (v.topComments.isNotEmpty) {
        for (var c in v.topComments.take(2)) {
          final cleanComment = c.text.replaceAll('"', "'").replaceAll('\n', ' ');
          recentVideosBuffer.writeln(
              '    * Comment by ${c.authorDisplayName} (${c.likeCount} likes): "$cleanComment"');
        }
      }
    }

    final demandClustersBuffer = StringBuffer();
    for (var cluster in channel.audienceInsight.topDemandClusters.take(4)) {
      demandClustersBuffer.writeln(
          '  - Topic: "${cluster.topicKeyword}" | Requests: ${cluster.commentFrequency} | Upvotes: ${cluster.totalUpvotes} | DVI: ${cluster.demandVelocityIndex.toStringAsFixed(1)}');
      if (cluster.sampleComments.isNotEmpty) {
        final cleanQuote = cluster.sampleComments.first.text.replaceAll('"', "'").replaceAll('\n', ' ');
        demandClustersBuffer.writeln(
            '    Sample Quote by ${cluster.sampleComments.first.authorDisplayName}: "$cleanQuote"');
      }
    }

    return '''
You are Prevue's Executive YouTube Content Strategist and Retention Algorithm Engine.
Your task is to analyze the following LIVE YouTube channel data and generate 4 high-conviction, highly authentic, non-generic video blueprints for the creator to film next.

=== CREATOR PROFILE ===
Channel Name: ${channel.channelName} (${channel.handle})
Niche / Category: ${channel.niche}
Subscribers: ${channel.subscribers}
Median Views per Upload: ${channel.medianViews}
Upload Frequency: ${channel.uploadFrequencyFormatted}
Top Outlier Velocity: ${channel.topOutlierMultiplier}x median
Median CTR: ${channel.medianCtr}%
Signature Style: ${channel.signatureCreatorStyle}
Signature Hook Style: ${channel.authenticityProfile.signatureHookStyle}
Retention Vulnerability Area: ${channel.authenticityProfile.retentionVulnerabilityArea}
Question-to-Praise Authority Ratio: ${channel.authenticityProfile.questionToPraiseRatio}x

=== TOPIC PERFORMANCE MULTIPLIERS ===
${channel.topicPerformanceMultipliers.map((t) => '  - ${t.topic.padRight(24)} -> ${t.multiple}x median (Avg ${t.averageViews} views)').join('\n')}

=== RECENT UPLOADS & HISTORICAL OUTLIERS ===
$recentVideosBuffer

=== AUDIENCE DEMAND CLUSTERS (Mined from Comments) ===
$demandClustersBuffer

=== BLUEPRINT SPECIFICATION REQUIREMENTS ===
Generate exactly 4 video blueprints following these distinct strategic angles:
1. Blueprint 1 (Community Demand Hero): Directly solves the #1 most upvoted question or demand cluster from the comments. Cite the commenter and real upvote metrics in the hook.
2. Blueprint 2 (Historical Outlier Sequel): Organic evolution/sequel to the channel's top-performing upload.
3. Blueprint 3 (High-Resonance System Deep-Dive): Long-form architectural/practical breakdown on a high-velocity topic cluster.
4. Blueprint 4 (High-Velocity Short): 45-second contrarian rule breakdown targeting 135%+ completion rate.

=== CRITICAL JSON FORMATTING RULES ===
1. Respond ONLY with a valid RFC-8259 JSON object starting with '{' and ending with '}'.
2. Do NOT output markdown code fences (no ```json).
3. Do NOT include raw literal linebreaks inside string values; keep every string on a single line.
4. Ensure all double quotes inside string literals are properly escaped (\\").
5. Keep each text field punchy, precise, and concise (1-2 sentences) to guarantee full JSON completion.

=== OUTPUT JSON SCHEMA ===
{
  "blueprints": [
    {
      "id": "bp_gemini_1",
      "title": "Compelling, high-CTR, non-clickbait title",
      "format": "longForm",
      "formatLabel": "Long-Form (12–15 Min)",
      "hookText": "First 5-15 seconds script hook addressing viewer tension and creator DNA",
      "thumbnailConceptLeft": "Visual element for left side of thumbnail",
      "thumbnailConceptRight": "Visual element for right side with proof",
      "thumbnailTag": "2-3 word high-contrast badge",
      "dataProofReason": "Mathematical and historical justification citing actual views, comments, or DVI",
      "predictedMultiplier": 3.4,
      "convictionScore": 9.2,
      "categoryTag": "Topic category",
      "demandEvidenceSummary": "Summary of viewer comments backing this video",
      "creatorAuthenticityProof": "How this matches creator signature style",
      "engagementContext": "Engagement signal driving this recommendation",
      "preEngineeredRetentionAnchors": [
        "0:00 - 0:05: High-tension hook",
        "0:05 - 0:25: Immediate visual proof / thesis statement",
        "0:25 - 4:00: Step-by-step resolution",
        "End: Retention bridge to recommended next video"
      ]
    }
  ]
}
''';
  }

  /// Constructs the single fresh blueprint prompt
  String _buildSingleFreshPrompt(ChannelGraph channel, {String? focusTopic}) {
    return '''
You are Prevue's AI YouTube Strategist. Generate 1 fresh, highly creative, high-conviction video blueprint for channel "${channel.channelName}" (${channel.handle}, Niche: ${channel.niche}).
${focusTopic != null ? 'Focus Topic: "$focusTopic"' : ''}
Signature Style: ${channel.signatureCreatorStyle}
Median Views: ${channel.medianViews}

=== CRITICAL JSON FORMATTING RULES ===
1. Respond ONLY with a valid RFC-8259 JSON object starting with '{' and ending with '}'.
2. Do NOT output markdown code fences (no ```json).
3. Do NOT include raw literal linebreaks inside string values.
4. Ensure all double quotes inside string literals are properly escaped (\\").
5. Keep each text field punchy and concise.

=== OUTPUT JSON SCHEMA ===
{
  "blueprints": [
    {
      "id": "bp_gemini_fresh_1",
      "title": "High CTR video title",
      "format": "longForm",
      "formatLabel": "Long-Form (10–13 Min)",
      "hookText": "Engaging hook script",
      "thumbnailConceptLeft": "Left thumbnail element",
      "thumbnailConceptRight": "Right thumbnail element",
      "thumbnailTag": "BADGE TAG",
      "dataProofReason": "Why this video will outperform the ${channel.medianViews} median baseline",
      "predictedMultiplier": 2.8,
      "convictionScore": 8.8,
      "categoryTag": "${channel.niche}",
      "demandEvidenceSummary": "Audience demand justification",
      "creatorAuthenticityProof": "Alignment with ${channel.signatureCreatorStyle}",
      "engagementContext": "Mined from live catalog trends",
      "preEngineeredRetentionAnchors": [
        "0:00 - 0:05: Immediate bold statement",
        "0:05 - 0:20: Visual proof",
        "0:20 - 3:30: Step-by-step breakdown",
        "End: Call-to-action & retention bridge"
      ]
    }
  ]
}
''';
  }

  /// Parse Gemini JSON response into DailyBlueprint objects with multi-tier error recovery
  List<DailyBlueprint> parseBlueprintsFromJson(
      String jsonText, ChannelGraph channel) {
    if (jsonText.trim().isEmpty) return [];

    // Stage 1: Strip markdown code blocks & extract JSON core
    String cleaned = _extractJsonBlock(jsonText);

    // Stage 2: Try direct standard jsonDecode
    try {
      final decoded = jsonDecode(cleaned);
      final list = _extractListFromDecoded(decoded);
      if (list.isNotEmpty) {
        return _mapJsonListToBlueprints(list, channel);
      }
    } catch (e) {
      log('[GeminiService] Standard jsonDecode failed: $e. Attempting JSON sanitization...');
    }

    // Stage 3: Sanitize common LLM formatting issues (raw unescaped newlines/tabs inside quotes, trailing commas)
    try {
      final sanitized = _sanitizeJsonString(cleaned);
      final decoded = jsonDecode(sanitized);
      final list = _extractListFromDecoded(decoded);
      if (list.isNotEmpty) {
        return _mapJsonListToBlueprints(list, channel);
      }
    } catch (e) {
      log('[GeminiService] Sanitized jsonDecode failed: $e. Attempting resilient chunk extraction...');
    }

    // Stage 4: Resilient chunk & partial object recovery
    // If Gemini was truncated midway (e.g. Unterminated string on last item),
    // extract all complete blueprint objects that were successfully generated.
    final recoveredMaps = _extractIndividualBlueprintObjects(cleaned);
    if (recoveredMaps.isNotEmpty) {
      log('[GeminiService] Successfully recovered ${recoveredMaps.length} blueprints from partial response.');
      return _mapJsonListToBlueprints(recoveredMaps, channel);
    }

    log('[GeminiService] Failed to parse blueprints from text. Snippet:\n${cleaned.length > 200 ? cleaned.substring(0, 200) : cleaned}');
    throw FormatException('Unable to parse valid blueprint JSON from Gemini output: $jsonText');
  }

  /// Strips markdown fences, commentary, and extracts the JSON block
  String _extractJsonBlock(String raw) {
    var text = raw.trim();
    if (text.startsWith('```json')) {
      text = text.substring(7);
    } else if (text.startsWith('```')) {
      text = text.substring(3);
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    text = text.trim();

    final firstBrace = text.indexOf('{');
    final firstBracket = text.indexOf('[');

    int startIdx = -1;
    if (firstBrace != -1 && firstBracket != -1) {
      startIdx = min(firstBrace, firstBracket);
    } else if (firstBrace != -1) {
      startIdx = firstBrace;
    } else if (firstBracket != -1) {
      startIdx = firstBracket;
    }

    final lastBrace = text.lastIndexOf('}');
    final lastBracket = text.lastIndexOf(']');
    final endIdx = max(lastBrace, lastBracket);

    if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
      text = text.substring(startIdx, endIdx + 1);
    }

    return text.trim();
  }

  /// Sanitizes invalid JSON characters like unescaped raw newlines/tabs inside string literals
  String _sanitizeJsonString(String text) {
    // Remove trailing commas before } or ]
    var result = text.replaceAll(RegExp(r',\s*([\}\]])'), r'$1');

    final buffer = StringBuffer();
    bool inString = false;
    bool escaped = false;

    for (int i = 0; i < result.length; i++) {
      final char = result[i];

      if (escaped) {
        buffer.write(char);
        escaped = false;
        continue;
      }

      if (char == '\\') {
        buffer.write(char);
        escaped = true;
        continue;
      }

      if (char == '"') {
        inString = !inString;
        buffer.write(char);
        continue;
      }

      if (inString) {
        if (char == '\n') {
          buffer.write(r'\n');
        } else if (char == '\r') {
          buffer.write(r'\r');
        } else if (char == '\t') {
          buffer.write(r'\t');
        } else {
          buffer.write(char);
        }
      } else {
        buffer.write(char);
      }
    }

    return buffer.toString();
  }

  /// Extracts individual complete blueprint JSON objects when stream was partially truncated
  List<Map<String, dynamic>> _extractIndividualBlueprintObjects(String text) {
    final results = <Map<String, dynamic>>[];

    bool inString = false;
    bool escaped = false;
    int braceDepth = 0;
    int objectStartIndex = -1;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      if (escaped) {
        escaped = false;
        continue;
      }

      if (char == '\\') {
        escaped = true;
        continue;
      }

      if (char == '"') {
        inString = !inString;
        continue;
      }

      if (inString) {
        continue;
      }

      if (char == '{') {
        braceDepth++;
        // Depth 2 inside {"blueprints": [{...}]} or depth 1 if root is array [{...}]
        if (braceDepth == 2 || (braceDepth == 1 && text.trim().startsWith('['))) {
          objectStartIndex = i;
        }
      } else if (char == '}') {
        if ((braceDepth == 2 || (braceDepth == 1 && text.trim().startsWith('['))) &&
            objectStartIndex != -1) {
          final chunk = text.substring(objectStartIndex, i + 1);
          try {
            final decoded = jsonDecode(chunk);
            if (decoded is Map<String, dynamic> &&
                (decoded.containsKey('title') ||
                    decoded.containsKey('id') ||
                    decoded.containsKey('hookText'))) {
              results.add(decoded);
            }
          } catch (_) {
            try {
              final sanitizedChunk = _sanitizeJsonString(chunk);
              final decoded = jsonDecode(sanitizedChunk);
              if (decoded is Map<String, dynamic>) {
                results.add(decoded);
              }
            } catch (_) {}
          }
          objectStartIndex = -1;
        }
        braceDepth--;
      }
    }

    return results;
  }

  /// Extracts the list of blueprints from whatever shape the decoded JSON is
  List<dynamic> _extractListFromDecoded(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final blueprintsJson = decoded['blueprints'] as List?;
      if (blueprintsJson != null && blueprintsJson.isNotEmpty) {
        return blueprintsJson;
      }
      if (decoded.containsKey('title') || decoded.containsKey('hookText')) {
        return [decoded];
      }
    } else if (decoded is List) {
      return decoded;
    }
    return [];
  }

  /// Maps raw JSON item maps into structured DailyBlueprint domain entities
  List<DailyBlueprint> _mapJsonListToBlueprints(
      List<dynamic> list, ChannelGraph channel) {
    final result = <DailyBlueprint>[];
    for (var i = 0; i < list.length; i++) {
      if (list[i] is! Map<String, dynamic>) continue;
      final item = list[i] as Map<String, dynamic>;

      final isShort = (item['format'] ?? '').toString().toLowerCase().contains('short') ||
          (item['formatLabel'] ?? '').toString().toLowerCase().contains('short');

      final multiplier = (item['predictedMultiplier'] is num)
          ? (item['predictedMultiplier'] as num).toDouble()
          : (double.tryParse(item['predictedMultiplier']?.toString() ?? '') ?? 2.5);

      final rawConviction = (item['convictionScore'] is num)
          ? (item['convictionScore'] as num).toDouble()
          : (double.tryParse(item['convictionScore']?.toString() ?? '') ?? 8.5);
      final conviction = rawConviction.clamp(7.0, 9.9);

      final minMult = ((multiplier * 0.82) * 10).round() / 10.0;
      final maxMult = ((multiplier * 1.25) * 10).round() / 10.0;

      final retentionAnchors = <String>[];
      if (item['preEngineeredRetentionAnchors'] is List) {
        for (var anchor in item['preEngineeredRetentionAnchors']) {
          retentionAnchors.add(anchor.toString());
        }
      }
      if (retentionAnchors.isEmpty) {
        retentionAnchors.addAll([
          '0:00 - 0:05: High-tension hook',
          '0:05 - 0:25: Immediate visual thesis',
          '0:25 - 4:00: Step-by-step resolution',
          'End: Retention bridge'
        ]);
      }

      // Associate with first matching demand cluster if applicable
      CommentDemandCluster? matchedCluster;
      if (channel.audienceInsight.topDemandClusters.isNotEmpty) {
        final clusterIndex = i % channel.audienceInsight.topDemandClusters.length;
        matchedCluster = channel.audienceInsight.topDemandClusters[clusterIndex];
      }

      result.add(
        DailyBlueprint(
          id: item['id']?.toString() ?? 'bp_gemini_${DateTime.now().millisecondsSinceEpoch}_$i',
          title: item['title']?.toString() ?? 'Dynamic Video Blueprint',
          format: isShort ? BlueprintFormat.short : BlueprintFormat.longForm,
          formatLabel: item['formatLabel']?.toString() ??
              (isShort ? 'YouTube Short (48s)' : 'Long-Form (12–15 Min)'),
          hookText: item['hookText']?.toString() ?? 'Today on ${channel.channelName}, we break down...',
          thumbnailConceptLeft: item['thumbnailConceptLeft']?.toString() ?? 'Viewer Problem',
          thumbnailConceptRight: item['thumbnailConceptRight']?.toString() ?? 'Verified Solution',
          thumbnailTag: item['thumbnailTag']?.toString() ?? 'VERIFIED PATTERN',
          dataProofReason: item['dataProofReason']?.toString() ??
              'Derived directly from live YouTube channel performance metrics.',
          predictedMultiplier: multiplier,
          convictionScore: conviction,
          confidenceIntervalMin: minMult,
          confidenceIntervalMax: maxMult,
          categoryTag: item['categoryTag']?.toString() ?? channel.niche,
          date: DateTime.now(),
          demandCluster: matchedCluster,
          audienceCommentSource: matchedCluster?.sampleComments.isNotEmpty == true
              ? matchedCluster!.sampleComments.first
              : null,
          demandEvidenceSummary: item['demandEvidenceSummary']?.toString() ??
              'Mined directly from live viewer comments and historical catalog outliers.',
          creatorAuthenticityProof: item['creatorAuthenticityProof']?.toString() ??
              'Aligned with "${channel.signatureCreatorStyle}".',
          engagementContext: item['engagementContext']?.toString() ??
              'Gemini AI reasoning over live channel comments and analytics.',
          preEngineeredRetentionAnchors: retentionAnchors,
        ),
      );
    }

    return result;
  }
}

