import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_profile.dart';
import 'backend_api_service.dart';
import 'revenue_cat_service.dart';

/// Authentication Service for Prevue
/// Manages user authentication, persistent local device storage, backend REST integration, and RevenueCat synchronization
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _prefUserKey = 'prevue_user_profile';
  static const String _prefTokenKey = 'prevue_auth_token';

  final RevenueCatService _revenueCatService = RevenueCatService();
  final BackendApiService _apiService = BackendApiService();

  UserProfile? _currentUser;

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  /// Initialize user session and restore persisted login after verifying DB existence
  Future<UserProfile?> initialize() async {
    if (_currentUser != null) return _currentUser;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final userJsonStr = prefs.getString(_prefUserKey);
      final token = prefs.getString(_prefTokenKey);
      if (userJsonStr != null && userJsonStr.isNotEmpty) {
        final Map<String, dynamic> jsonMap =
            jsonDecode(userJsonStr) as Map<String, dynamic>;
        final cachedUser = UserProfile.fromJson(jsonMap);
        final effectiveToken = (token != null && token.isNotEmpty)
            ? token
            : cachedUser.authToken;
        if (effectiveToken != null && effectiveToken.isNotEmpty) {
          _apiService.setAuthToken(effectiveToken);
        }

        // Live PostgreSQL verification: check user existence in database
        try {
          final liveUser = await _apiService.fetchUserProfile();
          if (liveUser != null) {
            _currentUser = liveUser;
            await _persistUser(liveUser);
          } else {
            _currentUser = cachedUser;
          }
        } catch (dbError) {
          // If server explicitly confirmed user was deleted or revoked (401/404)
          debugPrint(
            '[AuthService] ❌ User verification in DB failed ($dbError), signing out stale session',
          );
          await signOut();
          return null;
        }

        if (_currentUser != null) {
          await _syncWithRevenueCat(_currentUser!);
          debugPrint(
            '[AuthService] Restored persisted session for: ${_currentUser!.email} (Active: ${_currentUser!.activeChannelHandle})',
          );
        }
        return _currentUser;
      }
    } catch (e) {
      debugPrint('[AuthService] ⚠️ Error restoring user session, clearing corrupted cache: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_prefUserKey);
        await prefs.remove(_prefTokenKey);
      } catch (_) {}
    }
    return _currentUser;
  }

  /// 1-Tap Google Sign-In
  Future<UserProfile> signInWithGoogle({String? preferredHandle}) async {
    final user = await _apiService.googleAuth(preferredHandle: preferredHandle);
    _currentUser = user;
    await _persistUser(user);
    await _syncWithRevenueCat(user);
    debugPrint(
      '[AuthService] Signed in with Google: ${user.email} (ID: ${user.id})',
    );
    return user;
  }

  /// Sign In with Email and Password
  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) {
      throw Exception('Please enter your email address.');
    }
    if (!_emailRegex.hasMatch(cleanEmail)) {
      throw Exception('Please enter a valid email address.');
    }
    if (password.trim().isEmpty) {
      throw Exception('Please enter your password.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    final user = await _apiService.login(email: cleanEmail, password: password);
    _currentUser = user;
    await _persistUser(user);
    await _syncWithRevenueCat(user);
    debugPrint('[AuthService] Signed in with Email: ${user.email}');
    return user;
  }

  /// Sign Up with Email and Password
  Future<UserProfile> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String initialHandle,
  }) async {
    final cleanName = displayName.trim();
    if (cleanName.isEmpty) {
      throw Exception('Please enter your creator or brand name.');
    }

    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) {
      throw Exception('Please enter your email address.');
    }
    if (!_emailRegex.hasMatch(cleanEmail)) {
      throw Exception('Please enter a valid email address.');
    }

    if (password.trim().isEmpty) {
      throw Exception('Please enter a password.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    final rawHandle = initialHandle.trim();
    final cleanHandle = rawHandle.isNotEmpty
        ? (rawHandle.startsWith('@') ? rawHandle : '@$rawHandle')
        : '@${cleanName.replaceAll(RegExp(r'\s+'), '')}';

    final user = await _apiService.register(
      email: cleanEmail,
      password: password,
      displayName: cleanName,
      initialHandle: cleanHandle,
    );

    _currentUser = user;
    await _persistUser(user);
    await _syncWithRevenueCat(user);
    debugPrint(
      '[AuthService] Registered user: ${user.email} with channel ${user.activeChannelHandle}',
    );
    return user;
  }

  /// 1-Tap Demo Creator Switch (for Hackathon Judges)
  Future<UserProfile> signInWithDemoProfile(UserProfile demoProfile) async {
    await Future.delayed(const Duration(milliseconds: 350));
    _currentUser = demoProfile;
    _apiService.setAuthToken(demoProfile.authToken);
    await _persistUser(demoProfile);
    await _syncWithRevenueCat(demoProfile);
    debugPrint(
      '[AuthService] Switched to Demo Account: ${demoProfile.displayName}',
    );
    return demoProfile;
  }

  /// Sign Out and Revert to Unauthenticated
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 250));
    await _revenueCatService.logOut();
    _apiService.setAuthToken(null);
    _currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefUserKey);
      await prefs.remove(_prefTokenKey);
    } catch (e) {
      debugPrint('[AuthService] Error clearing persisted session: $e');
    }
    debugPrint('[AuthService] User signed out');
  }

  /// Add a new connected YouTube channel
  Future<UserProfile> addChannel(String handle, {required bool isPro}) async {
    if (_currentUser == null) throw Exception('User is not authenticated.');

    final updatedChannels = await _apiService.addChannel(
      handle: handle,
      currentChannels: _currentUser!.connectedChannels,
      isPro: isPro,
    );

    final cleanHandle = handle.startsWith('@') ? handle : '@$handle';
    _currentUser = _currentUser!.copyWith(
      connectedChannels: updatedChannels,
      activeChannelHandle: cleanHandle,
    );

    await _persistUser(_currentUser!);
    await _revenueCatService.setUserAttributes(
      activeChannel: cleanHandle,
      channelCount: updatedChannels.length,
    );
    return _currentUser!;
  }

  /// Remove a connected YouTube channel
  Future<UserProfile> removeChannel(String handle) async {
    if (_currentUser == null) throw Exception('User is not authenticated.');

    if (_currentUser!.connectedChannels.length <= 1) {
      throw Exception('You must keep at least one connected channel.');
    }

    final updatedList = List<String>.from(_currentUser!.connectedChannels)
      ..remove(handle);
    final newActive = _currentUser!.activeChannelHandle == handle
        ? updatedList.first
        : _currentUser!.activeChannelHandle;

    _currentUser = _currentUser!.copyWith(
      connectedChannels: updatedList,
      activeChannelHandle: newActive,
    );

    await _persistUser(_currentUser!);
    await _revenueCatService.setUserAttributes(
      activeChannel: newActive,
      channelCount: updatedList.length,
    );
    return _currentUser!;
  }

  /// Switch active YouTube channel
  Future<UserProfile> switchActiveChannel(String handle) async {
    if (_currentUser == null) throw Exception('User is not authenticated.');

    final cleanHandle = handle.startsWith('@') ? handle : '@$handle';
    if (!_currentUser!.connectedChannels.contains(cleanHandle)) {
      await addChannel(cleanHandle, isPro: true);
    } else {
      _currentUser = _currentUser!.copyWith(activeChannelHandle: cleanHandle);
      await _persistUser(_currentUser!);
      await _revenueCatService.setUserAttributes(
        activeChannel: cleanHandle,
        channelCount: _currentUser!.connectedChannels.length,
      );
    }
    return _currentUser!;
  }

  /// Persist user profile and auth token to device storage
  Future<void> _persistUser(UserProfile user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(_prefUserKey, userJson);
      if (user.authToken != null && user.authToken!.isNotEmpty) {
        await prefs.setString(_prefTokenKey, user.authToken!);
      }
      debugPrint(
        '[AuthService] 💾 Persisted user session to local storage for: ${user.email}',
      );
    } catch (e) {
      debugPrint('[AuthService] ❌ Could not persist user session: $e');
    }
  }

  /// Internal synchronization with RevenueCat
  Future<void> _syncWithRevenueCat(UserProfile user) async {
    try {
      await _revenueCatService.logIn(user.id);
      await _revenueCatService.setUserAttributes(
        email: user.email,
        displayName: user.displayName,
        activeChannel: user.activeChannelHandle,
        channelCount: user.connectedChannels.length,
      );
    } catch (e) {
      debugPrint('[AuthService] ⚠️ RevenueCat sync non-fatal error: $e');
    }
  }
}
