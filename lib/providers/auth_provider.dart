import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Authentication status enum used by the router to determine which
/// screen stack to display.
enum AuthStatus { loading, authenticated, unauthenticated }

/// Custom exception for unverified user flow
class UserNotVerifiedException implements Exception {
  const UserNotVerifiedException();
}

/// Central auth state manager.
/// The RouterDelegate listens to this provider and rebuilds the
/// navigation stack whenever [authStatus] changes.
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _authStatus = AuthStatus.loading;
  UserModel? _currentUser;
  String? _errorMessage;
  bool _isBusy = false; // true while an HTTP request is in-flight

  // ── Getters ───────────────────────────────────────────────────────────
  AuthStatus get authStatus => _authStatus;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isBusy => _isBusy;

  // ── SharedPreferences key ─────────────────────────────────────────────
  static const String _userKey = 'current_user';

  // ── Check Session ─────────────────────────────────────────────────────
  /// Called on app launch from the splash screen.
  /// Reads persisted user data from SharedPreferences.
  Future<void> checkSession() async {
    _authStatus = AuthStatus.loading;
    notifyListeners();

    // Splash delay
    await Future.delayed(const Duration(milliseconds: 1500));

    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);

    if (userData != null) {
      _currentUser = UserModel.decode(userData);
      _authStatus = AuthStatus.authenticated;
    } else {
      _authStatus = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  // ── Login ─────────────────────────────────────────────────────────────
  /// Calls POST /login, persists user on success.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _errorMessage = null;
    _isBusy = true;
    notifyListeners();

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      // Extract user and tokens from response
      final userJson = response['user'] as Map<String, dynamic>;
      userJson['accessToken'] = response['accessToken'];
      userJson['refreshToken'] = response['refreshToken'];
      _currentUser = UserModel.fromJson(userJson);

      // Persist session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, _currentUser!.encode());

      _authStatus = AuthStatus.authenticated;
      _isBusy = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      if (e.message == 'User is not verified') {
        _isBusy = false;
        notifyListeners();
        throw const UserNotVerifiedException();
      }
      _errorMessage = e.message;
      _isBusy = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Connection error. Please try again.';
      _isBusy = false;
      notifyListeners();
      return false;
    }
  }

  /// Calls POST /signup.
  /// Does NOT auto-verify. Returns true on success so UI can navigate to OTP screen.
  Future<bool> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _errorMessage = null;
    _isBusy = true;
    notifyListeners();

    try {
      await _authService.signup(
        fullName: fullName,
        email: email,
        password: password,
      );

      _isBusy = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isBusy = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Connection error. Please try again.';
      _isBusy = false;
      notifyListeners();
      return false;
    }
  }

  // ── Verify OTP and Login ──────────────────────────────────────────────
  Future<bool> verifyOtpAndLogin({
    required String email,
    required String otp,
  }) async {
    _errorMessage = null;
    _isBusy = true;
    notifyListeners();

    try {
      final response = await _authService.verifyOtp(email: email, otp: otp);

      // Extract user and tokens
      final userJson = response['user'] as Map<String, dynamic>;
      userJson['accessToken'] = response['accessToken'];
      userJson['refreshToken'] = response['refreshToken'];
      _currentUser = UserModel.fromJson(userJson);

      // Persist session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, _currentUser!.encode());

      _authStatus = AuthStatus.authenticated;
      _isBusy = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isBusy = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Connection error. Please try again.';
      _isBusy = false;
      notifyListeners();
      return false;
    }
  }

  // ── Resend OTP ────────────────────────────────────────────────────────
  Future<bool> resendOtp({required String email}) async {
    _errorMessage = null;
    _isBusy = true;
    notifyListeners();

    try {
      await _authService.resendOtp(email: email);
      _isBusy = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isBusy = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Connection error. Please try again.';
      _isBusy = false;
      notifyListeners();
      return false;
    }
  }

  // ── Forgot Password ───────────────────────────────────────────────────
  Future<bool> forgotPassword({required String email}) async {
    _errorMessage = null;
    _isBusy = true;
    notifyListeners();

    try {
      await _authService.forgotPassword(email: email);
      _isBusy = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isBusy = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Connection error. Please try again.';
      _isBusy = false;
      notifyListeners();
      return false;
    }
  }

  // ── Verify Reset OTP ──────────────────────────────────────────────────
  Future<bool> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    _errorMessage = null;
    _isBusy = true;
    notifyListeners();

    try {
      await _authService.verifyResetOtp(email: email, otp: otp);
      _isBusy = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isBusy = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Connection error. Please try again.';
      _isBusy = false;
      notifyListeners();
      return false;
    }
  }

  // ── Reset Password ────────────────────────────────────────────────────
  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _errorMessage = null;
    _isBusy = true;
    notifyListeners();

    try {
      final response = await _authService.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );

      // Extract user and tokens
      final userJson = response['user'] as Map<String, dynamic>;
      userJson['accessToken'] = response['accessToken'];
      userJson['refreshToken'] = response['refreshToken'];
      _currentUser = UserModel.fromJson(userJson);

      // Persist session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, _currentUser!.encode());

      _authStatus = AuthStatus.authenticated;
      _isBusy = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isBusy = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Connection error. Please try again.';
      _isBusy = false;
      notifyListeners();
      return false;
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────
  /// Launches the Google account picker, then calls POST /auth/google.
  /// On success, persists session and navigates to HomeScreen.
  Future<bool> signInWithGoogle() async {
    _errorMessage = null;
    _isBusy = true;
    notifyListeners();

    try {
      final googleSignIn = GoogleSignIn(
        // iOS: uses clientId (no GoogleService-Info.plist without Firebase)
        clientId: dotenv.env['GOOGLE_IOS_CLIENT_ID'],
        // Android: uses serverClientId (web client ID) to obtain an idToken
        serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
      );

      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the picker
        _isBusy = false;
        notifyListeners();
        return false;
      }

      final response = await _authService.googleSignIn(
        email: googleUser.email,
        fullName: googleUser.displayName ?? 'Google User',
        googleId: googleUser.id,
      );

      final userJson = response['user'] as Map<String, dynamic>;
      userJson['accessToken'] = response['accessToken'] as String? ?? '';
      userJson['refreshToken'] = response['refreshToken'] as String? ?? '';
      _currentUser = UserModel.fromJson(userJson);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, _currentUser!.encode());

      _authStatus = AuthStatus.authenticated;
      _isBusy = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isBusy = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Google sign-in failed. Please try again.';
      _isBusy = false;
      notifyListeners();
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────
  /// Clears persisted session and resets state.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);

    _currentUser = null;
    _authStatus = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clears any displayed error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
