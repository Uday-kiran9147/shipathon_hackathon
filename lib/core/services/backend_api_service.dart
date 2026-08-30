import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../network/api_endpoints.dart';
import '../../models/user_profile.dart';

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
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
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
      authToken: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );
    setAuthToken(user.authToken);
    return user;
  }
}
