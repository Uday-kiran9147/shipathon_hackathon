import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../network/api_endpoints.dart';
import '../../models/user_profile.dart';
import '../../models/channel_graph.dart';
import '../../models/daily_blueprint.dart';

/// Backend API Service for Prevue
/// Integrates all REST endpoints defined in API_DOCUMENTATION.md with dual-mode resilience:
/// - Connects to live Prevue Backend API Gateway (PostgreSQL) when available
/// - Provides realistic high-fidelity demo execution for offline/standalone hackathon testing
class BackendApiService {
  static final BackendApiService _instance = BackendApiService._internal();
  factory BackendApiService() => _instance;

  late final Dio _dio;
  String? _authToken;
  bool _mockMode =
      false; // Set to false to actively write to live backend & local PostgreSQL

  BackendApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        // Channel sync (live YouTube mining) and briefing generation (Gemini)
        // legitimately take longer than a typical request; a short timeout
        // here just makes a slow-but-successful backend look like a failure.
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 45),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          debugPrint('🌐 [HTTP Request] ${options.method} -> ${options.uri}');
          if (options.data != null) {
            debugPrint('📦 [HTTP Payload] ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            '🟢 [HTTP Response] ${response.statusCode} <- ${response.requestOptions.path}',
          );
          debugPrint('📄 [HTTP Response Body] ${response.data}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint(
            '🔴 [HTTP Error] ${e.type} -> ${e.message} (status: ${e.response?.statusCode})',
          );
          if (e.response?.data != null) {
            debugPrint('⚠️ [HTTP Error Body] ${e.response?.data}');
          }
          return handler.next(e);
        },
      ),
    );
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  void setMockMode(bool isMock) {
    _mockMode = isMock;
  }

  bool get isMockMode => _mockMode;

  /// Helper to extract human-readable error messages from DioException
  String _extractErrorMessage(DioException error, String fallback) {
    if (error.response?.data != null) {
      final data = error.response!.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        } else if (message is List && message.isNotEmpty) {
          return message.first.toString();
        }
        final errorField = data['error'];
        if (errorField is String && errorField.isNotEmpty) {
          return errorField;
        }
      } else if (data is String &&
          data.isNotEmpty &&
          !data.contains('<!DOCTYPE') &&
          !data.contains('PNG')) {
        return data;
      }
    }
    final status = error.response?.statusCode;
    if (status == 401) {
      return 'Invalid email or password.';
    } else if (status == 400) {
      return 'Invalid request data. Please check your inputs.';
    } else if (status == 403) {
      return 'Access denied. You do not have permission.';
    } else if (status == 409) {
      return 'An account with this email already exists.';
    } else if (status != null && status >= 500) {
      return 'Server is temporarily unavailable. Please try again.';
    }
    return fallback;
  }

  /// POST /api/v1/auth/register
  Future<UserProfile> register({
    required String email,
    required String password,
    required String displayName,
    required String initialHandle,
  }) async {
    final cleanHandle = initialHandle.trim().startsWith('@')
        ? initialHandle.trim()
        : '@${initialHandle.trim()}';

    if (_mockMode) {
      debugPrint(
        '[BackendApiService] Running in explicit mock mode for register',
      );
      return _generateMockUser(
        email: email,
        displayName: displayName,
        handle: cleanHandle,
      );
    }

    try {
      debugPrint(
        '[BackendApiService] 🚀 Sending POST ${ApiEndpoints.baseUrl}${ApiEndpoints.authRegister}',
      );
      final response = await _dio.post(
        ApiEndpoints.authRegister,
        data: {
          'email': email.trim(),
          'password': password,
          'displayName': displayName.trim(),
          'initialHandle': cleanHandle,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final user = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
      setAuthToken(data['token'] as String?);
      debugPrint(
        '[BackendApiService] ✅ User created in PostgreSQL: ${user.email} (ID: ${user.id})',
      );
      return user;
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode != null && e.response!.statusCode! >= 400) {
        final errorMsg = _extractErrorMessage(e, 'Registration failed.');
        debugPrint('[BackendApiService] 🔴 Live register error ${e.response?.statusCode}: $errorMsg');
        throw Exception(errorMsg);
      }
      debugPrint(
        '[BackendApiService] ⚠️ Live register network error ($e), falling back to offline profile',
      );
      return _generateMockUser(
        email: email,
        displayName: displayName,
        handle: cleanHandle,
      );
    } catch (e) {
      if (e is Exception) rethrow;
      debugPrint(
        '[BackendApiService] ⚠️ Live register fallback for: $e',
      );
      return _generateMockUser(
        email: email,
        displayName: displayName,
        handle: cleanHandle,
      );
    }
  }

  /// POST /api/v1/auth/login
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    if (_mockMode) {
      debugPrint('[BackendApiService] Running in explicit mock mode for login');
      return _generateMockUser(
        email: email,
        displayName: 'Creator',
        handle: '@RevenueCat',
      );
    }

    try {
      debugPrint(
        '[BackendApiService] 🚀 Sending POST ${ApiEndpoints.baseUrl}${ApiEndpoints.authLogin}',
      );
      final response = await _dio.post(
        ApiEndpoints.authLogin,
        data: {'email': email.trim(), 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      final user = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
      setAuthToken(data['token'] as String?);
      debugPrint(
        '[BackendApiService] ✅ User logged in from PostgreSQL: ${user.email} (ID: ${user.id})',
      );
      return user;
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode != null && e.response!.statusCode! >= 400) {
        final errorMsg = _extractErrorMessage(e, 'Invalid email or password.');
        debugPrint('[BackendApiService] 🔴 Live login error ${e.response?.statusCode}: $errorMsg');
        throw Exception(errorMsg);
      }
      debugPrint(
        '[BackendApiService] ⚠️ Live login network error ($e), falling back to offline profile',
      );
      return _generateMockUser(
        email: email,
        displayName: 'Creator',
        handle: '@RevenueCat',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      debugPrint(
        '[BackendApiService] ⚠️ Live login fallback for: $e',
      );
      return _generateMockUser(
        email: email,
        displayName: 'Creator',
        handle: '@RevenueCat',
      );
    }
  }

  /// POST /api/v1/auth/google
  Future<UserProfile> googleAuth({
    String? idToken,
    String? preferredHandle,
  }) async {
    final targetHandle =
        (preferredHandle != null && preferredHandle.trim().isNotEmpty)
        ? (preferredHandle.trim().startsWith('@')
              ? preferredHandle.trim()
              : '@${preferredHandle.trim()}')
        : '@RevenueCat';

    if (_mockMode) {
      return _generateMockUser(
        email: 'creator.google@gmail.com',
        displayName: 'Google Verified Creator',
        handle: targetHandle,
        photoUrl:
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      );
    }

    try {
      debugPrint(
        '[BackendApiService] 🚀 Sending POST ${ApiEndpoints.baseUrl}${ApiEndpoints.authGoogle}',
      );
      final response = await _dio.post(
        ApiEndpoints.authGoogle,
        data: {
          'idToken': idToken ?? 'mock_google_id_token',
          'preferredHandle': targetHandle,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final user = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
      setAuthToken(data['token'] as String?);
      debugPrint(
        '[BackendApiService] ✅ Google user authenticated in PostgreSQL: ${user.email}',
      );
      return user;
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode != null && e.response!.statusCode! >= 400) {
        final errorMsg = _extractErrorMessage(e, 'Google authentication failed.');
        debugPrint('[BackendApiService] 🔴 Live Google auth error ${e.response?.statusCode}: $errorMsg');
        throw Exception(errorMsg);
      }
      debugPrint(
        '[BackendApiService] ⚠️ Live Google auth network error ($e), using local profile',
      );
      return _generateMockUser(
        id: 'usr_google_${DateTime.now().millisecondsSinceEpoch}',
        email: 'creator.google@gmail.com',
        displayName: 'Google Verified Creator',
        handle: targetHandle,
        photoUrl:
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      return _generateMockUser(
        id: 'usr_google_${DateTime.now().millisecondsSinceEpoch}',
        email: 'creator.google@gmail.com',
        displayName: 'Google Verified Creator',
        handle: targetHandle,
        photoUrl:
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      );
    }
  }

  /// GET /api/v1/user/profile
  /// Validates user existence and returns current profile from PostgreSQL database
  Future<UserProfile?> fetchUserProfile() async {
    if (_authToken == null || _authToken!.isEmpty) return null;

    if (_mockMode) {
      return null;
    }

    try {
      debugPrint(
        '[BackendApiService] 🔍 Checking user existence in PostgreSQL: ${ApiEndpoints.baseUrl}${ApiEndpoints.userProfile}',
      );
      final response = await _dio.get(ApiEndpoints.userProfile);
      final data = response.data as Map<String, dynamic>;
      if (data['user'] != null) {
        final user = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
        debugPrint(
          '[BackendApiService] ✅ User verified in PostgreSQL database: ${user.email} (ID: ${user.id})',
        );
        return user;
      }
      return null;
    } on DioException catch (e) {
      if (e.response != null &&
          (e.response!.statusCode == 401 || e.response!.statusCode == 404)) {
        debugPrint(
          '[BackendApiService] ❌ User does not exist or token revoked in PostgreSQL (Status: ${e.response?.statusCode})',
        );
        throw Exception('User account not found in database.');
      }
      debugPrint(
        '[BackendApiService] ⚠️ fetchUserProfile network error ($e), retaining offline cache',
      );
      return null;
    } catch (e) {
      debugPrint('[BackendApiService] ⚠️ fetchUserProfile error: $e');
      return null;
    }
  }

  /// POST /api/v1/user/channels
  Future<List<String>> addChannel({
    required String handle,
    required List<String> currentChannels,
    required bool isPro,
  }) async {
    final cleanHandle = handle.trim().startsWith('@')
        ? handle.trim()
        : '@${handle.trim()}';

    if (!isPro &&
        currentChannels.isNotEmpty &&
        !currentChannels.contains(cleanHandle)) {
      throw Exception(
        'Multi-channel workspace requires Creator Pro. Unlock Pro to manage up to 5 channels.',
      );
    }

    if (!currentChannels.contains(cleanHandle)) {
      final updated = List<String>.from(currentChannels)..add(cleanHandle);
      try {
        debugPrint(
          '[BackendApiService] 🚀 Sending POST ${ApiEndpoints.baseUrl}${ApiEndpoints.userChannels}',
        );
        await _dio.post(
          ApiEndpoints.userChannels,
          data: {'handle': cleanHandle, 'isPro': isPro},
        );
        debugPrint(
          '[BackendApiService] ✅ Channel added to PostgreSQL: $cleanHandle',
        );
      } catch (e) {
        debugPrint(
          '[BackendApiService] ⚠️ Live addChannel failed ($e), updated in local state',
        );
      }
      return updated;
    }
    return currentChannels;
  }

  /// POST /api/channel/sync
  /// Runs the Channel Graph context engine (YouTube mining, comment intent
  /// classification, demand clustering, authenticity profiling) on the
  /// backend and returns the resulting ChannelGraph.
  Future<ChannelGraph> syncChannel(String handle) async {
    final cleanHandle = handle.trim().startsWith('@')
        ? handle.trim()
        : '@${handle.trim()}';

    try {
      debugPrint(
        '[BackendApiService] 🚀 Sending POST ${ApiEndpoints.baseUrl}${ApiEndpoints.channelSync}',
      );
      final response = await _dio.post(
        ApiEndpoints.channelSync,
        data: {'handle': cleanHandle},
      );
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['channel'] is Map<String, dynamic>) {
          final channelJson = data['channel'] as Map<String, dynamic>;
          debugPrint(
            '[BackendApiService] ✅ Channel Graph synced from backend: $cleanHandle',
          );
          return ChannelGraph.fromJson(channelJson);
        }
      }
      throw Exception('Invalid channel sync payload returned by server.');
    } on DioException catch (e) {
      final errorMsg =
          _extractErrorMessage(e, 'Failed to sync channel from YouTube API.');
      debugPrint('[BackendApiService] 🔴 syncChannel error: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to sync channel: $e');
    }
  }

  /// POST /api/briefing/generate
  /// Runs the Daily Prescriptive Briefing engine on the backend
  /// (Gemini blueprint synthesis with algorithmic fallback) and returns
  /// the generated blueprints.
  Future<List<DailyBlueprint>> generateBriefing(ChannelGraph channel) async {
    debugPrint(
      '[BackendApiService] 🚀 Sending POST ${ApiEndpoints.baseUrl}${ApiEndpoints.briefingsGenerate}',
    );
    final response = await _dio.post(
      ApiEndpoints.briefingsGenerate,
      data: {'channel': channel.toJson()},
    );
    final data = response.data as Map<String, dynamic>;
    final rawBlueprints = data['blueprints'] as List<dynamic>? ?? [];
    debugPrint(
      '[BackendApiService] ✅ Briefing generated from backend: ${rawBlueprints.length} blueprints',
    );
    return rawBlueprints
        .map((b) => DailyBlueprint.fromJson(b as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/briefing/history
  /// Returns previously generated & persisted briefing batches for the
  /// authenticated user (used for a future "past prescriptions" view and
  /// shared as-is with the planned web client).
  Future<List<Map<String, dynamic>>> getBriefingHistory() async {
    try {
      final response = await _dio.get(ApiEndpoints.briefingsHistory);
      final data = response.data as Map<String, dynamic>;
      final rawBriefings = data['briefings'] as List<dynamic>? ?? [];
      return rawBriefings.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[BackendApiService] ⚠️ getBriefingHistory failed ($e)');
      return [];
    }
  }

  /// GET /api/v1/simulator/history
  /// Returns previously run & persisted simulations for the authenticated
  /// user (raw DB row shape: hook_score, performance_tier, draft_script, etc.).
  Future<List<Map<String, dynamic>>> getSimulationHistory() async {
    try {
      final response = await _dio.get(ApiEndpoints.simulatorHistory);
      final data = response.data as Map<String, dynamic>;
      final rawSimulations = data['simulations'] as List<dynamic>? ?? [];
      return rawSimulations.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[BackendApiService] ⚠️ getSimulationHistory failed ($e)');
      return [];
    }
  }

  /// POST /api/v1/simulator/run
  Future<Map<String, dynamic>?> runSimulationOnBackend({
    required String title,
    required String draftScript,
    required BlueprintFormat format,
    required ChannelGraph channel,
  }) async {
    if (_mockMode) return null;

    try {
      debugPrint(
        '[BackendApiService] 🚀 Sending POST ${ApiEndpoints.baseUrl}${ApiEndpoints.simulatorRun}',
      );
      final response = await _dio.post(
        ApiEndpoints.simulatorRun,
        data: {
          'title': title.trim(),
          'draftScript': draftScript.trim(),
          'script': draftScript.trim(),
          'format': format == BlueprintFormat.short ? 'short' : 'longForm',
          'channelHandle': channel.handle,
          'medianViews': channel.medianViews,
        },
      );
      final data = response.data as Map<String, dynamic>;
      debugPrint('[BackendApiService] ✅ Simulation ran on backend PostgreSQL');
      return data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode == 403) {
        final data = e.response?.data;
        final errorMsg = (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'Free simulation limit reached (3/3). Unlock Creator Pro for unlimited pre-flight simulations.';
        debugPrint('[BackendApiService] 🚫 Pro required 403: $errorMsg');
        throw Exception(errorMsg);
      }
      debugPrint('[BackendApiService] ⚠️ runSimulationOnBackend network fallback ($e)');
      return null;
    } catch (e) {
      if (e is Exception && e.toString().contains('Free simulation limit')) {
        rethrow;
      }
      debugPrint('[BackendApiService] ⚠️ runSimulationOnBackend error ($e)');
      return null;
    }
  }

  /// Helper to generate resilient mock user
  UserProfile _generateMockUser({
    String? id,
    required String email,
    required String displayName,
    required String handle,
    String? photoUrl,
  }) {
    final user = UserProfile(
      id: id ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim(),
      displayName: displayName.trim().isNotEmpty
          ? displayName.trim()
          : 'Creator',
      photoUrl: photoUrl,
      connectedChannels: [handle],
      activeChannelHandle: handle,
      isGuest: false,
      isPro: false,
      simulationsUsedThisMonth: 0,
      freeSimulationsLimit: 3,
      authToken: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );
    setAuthToken(user.authToken);
    return user;
  }
}
