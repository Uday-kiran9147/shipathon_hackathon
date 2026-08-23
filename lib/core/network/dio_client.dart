import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Custom Exception for YouTube API Errors
class YouTubeApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const YouTubeApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'YouTubeApiException: $message (status: $statusCode)';
}

/// Robust Dio HTTP Helper for YouTube Data API v3 and external requests
class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late final Dio dio;
  String? _apiKey;

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://www.googleapis.com/youtube/v3/',
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
        sendTimeout: const Duration(seconds: 12),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add Interceptors
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Automatically inject API key into query parameters if present
          if (_apiKey != null && _apiKey!.isNotEmpty) {
            options.queryParameters['key'] = _apiKey;
          }
          if (kDebugMode) {
            debugPrint('[Dio Request] ${options.method} -> ${options.uri}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('[Dio Response] ${response.statusCode} <- ${response.requestOptions.path}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (kDebugMode) {
            debugPrint('[Dio Error] ${e.type} -> ${e.message} (status: ${e.response?.statusCode})');
          }
          final customException = _handleDioError(e);
          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              error: customException,
            ),
          );
        },
      ),
    );
  }

  void setApiKey(String? key) {
    _apiKey = key;
    if (kDebugMode) {
      debugPrint('[DioClient] YouTube API Key configured: ${key != null && key.isNotEmpty ? "YES (${key.substring(0, 4)}...)" : "NONE"}');
    }
  }

  String? get apiKey => _apiKey;

  YouTubeApiException _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const YouTubeApiException(
        message: 'Connection timed out. Please check your internet connection.',
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return const YouTubeApiException(
        message: 'Unable to connect to YouTube API server.',
      );
    }

    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    if (statusCode == 400) {
      return YouTubeApiException(
        message: 'Invalid request. Please check the channel handle or query parameter.',
        statusCode: 400,
        data: responseData,
      );
    } else if (statusCode == 403) {
      return YouTubeApiException(
        message: 'YouTube API quota exceeded or API key invalid/unauthorized.',
        statusCode: 403,
        data: responseData,
      );
    } else if (statusCode == 404) {
      return YouTubeApiException(
        message: 'YouTube channel not found.',
        statusCode: 404,
        data: responseData,
      );
    }

    return YouTubeApiException(
      message: e.message ?? 'An unexpected network error occurred.',
      statusCode: statusCode,
      data: responseData,
    );
  }

  // --- HTTP Methods ---

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.error is YouTubeApiException) {
        throw e.error as YouTubeApiException;
      }
      throw YouTubeApiException(message: e.message ?? 'Failed to execute GET request');
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.error is YouTubeApiException) {
        throw e.error as YouTubeApiException;
      }
      throw YouTubeApiException(message: e.message ?? 'Failed to execute POST request');
    }
  }
}
