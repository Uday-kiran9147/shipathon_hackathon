import 'package:flutter/foundation.dart';
import '../core/services/auth_service.dart';
import '../models/user_profile.dart';

/// Authentication and Workspace State Provider for Prevue
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserProfile? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  UserProfile? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  String get activeHandle => _user?.activeChannelHandle ?? '@RevenueCat';
  List<String> get connectedChannels => _user?.connectedChannels ?? const [];

  AuthProvider({UserProfile? initialUser}) {
    if (initialUser != null) {
      _user = initialUser;
      _isInitialized = true;
    } else {
      _init();
    }
  }

  Future<void> _init() async {
    try {
      _user = await _authService.initialize();
    } catch (e) {
      debugPrint('[AuthProvider] Error initializing auth session: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  String _formatErrorMessage(dynamic e) {
    if (e == null) return 'An unexpected error occurred.';
    final String message = e.toString().replaceAll('Exception: ', '').trim();
    if (message.startsWith('DioException')) {
      if (message.contains('401')) {
        return 'Invalid email or password.';
      } else if (message.contains('400') || message.contains('422')) {
        return 'Please verify your information and try again.';
      } else if (message.contains('409')) {
        return 'An account with this email already exists.';
      } else if (message.contains('timeout')) {
        return 'Connection timed out. Please check your internet connection.';
      } else {
        return 'Unable to reach the server. Please try again later.';
      }
    }
    return message;
  }

  /// 1-Tap Google Sign-In
  Future<bool> signInWithGoogle({String? preferredHandle}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithGoogle(
        preferredHandle: preferredHandle,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _formatErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Sign In with Email
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithEmail(
        email: email.trim(),
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _formatErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Sign Up with Email
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String initialHandle,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signUpWithEmail(
        email: email.trim(),
        password: password,
        displayName: displayName.trim(),
        initialHandle: initialHandle.trim(),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _formatErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Switch to Demo Account (for Hackathon Judges)
  Future<bool> signInWithDemoAccount(UserProfile demoAccount) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithDemoProfile(demoAccount);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Sign Out and Revert to Unauthenticated
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    await _authService.signOut();
    _user = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Add a YouTube Channel (Enforces Pro requirement for >1 channel)
  Future<bool> addChannel(String handle, {required bool isPro}) async {
    final cleanHandle = handle.trim().startsWith('@')
        ? handle.trim()
        : '@${handle.trim()}';

    if (_user == null) {
      _errorMessage = 'Please sign in to connect YouTube channels.';
      notifyListeners();
      return false;
    }

    // Free users are restricted to 1 connected channel
    if (!isPro &&
        _user!.connectedChannels.isNotEmpty &&
        !_user!.connectedChannels.contains(cleanHandle)) {
      _errorMessage =
          'Multi-channel workspace requires Creator Pro. Unlock Pro to manage up to 5 channels.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.addChannel(cleanHandle, isPro: isPro);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Remove a YouTube Channel
  Future<bool> removeChannel(String handle) async {
    if (_user == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.removeChannel(handle);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Switch the Active YouTube Channel
  Future<bool> switchActiveChannel(String handle) async {
    if (_user == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.switchActiveChannel(handle);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
