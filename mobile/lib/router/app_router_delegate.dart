import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../screens/auth_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/home_screen.dart';

import '../screens/otp_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/reset_otp_screen.dart';
import '../screens/new_password_screen.dart';

/// Which sub-screen is showing within the unauthenticated flow.
enum AuthSubRoute { landing, login, signup, otp, forgotPassword, resetOtp, newPassword }

/// Navigator 2.0 RouterDelegate that watches [AuthProvider] and
/// rebuilds the page stack based on auth status.
///
/// Flow:
///   loading         → SplashScreen
///   unauthenticated → AuthScreen (+ optionally LoginScreen / SignupScreen)
///   authenticated   → HomeScreen   (back stack cleared)
class AppRouterDelegate extends RouterDelegate<RouteInformation>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<RouteInformation> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final AuthProvider authProvider;

  /// Tracks which auth sub-screen is visible.
  AuthSubRoute _authSubRoute = AuthSubRoute.landing;
  String? _otpEmail;
  String? _resetEmail;
  String? _resetOtp;

  AppRouterDelegate({required this.authProvider}) {
    // Rebuild navigation whenever auth state changes.
    authProvider.addListener(notifyListeners);
  }

  // ── Public navigation methods (called from screens) ───────────────────
  void navigateToLogin() {
    _authSubRoute = AuthSubRoute.login;
    notifyListeners();
  }

  void navigateToSignup() {
    _authSubRoute = AuthSubRoute.signup;
    notifyListeners();
  }

  void navigateToAuth() {
    _authSubRoute = AuthSubRoute.landing;
    _otpEmail = null;
    notifyListeners();
  }

  void navigateToOtp(String email) {
    _authSubRoute = AuthSubRoute.otp;
    _otpEmail = email;
    notifyListeners();
  }

  void navigateToForgotPassword() {
    _authSubRoute = AuthSubRoute.forgotPassword;
    notifyListeners();
  }

  void navigateToResetOtp(String email) {
    _authSubRoute = AuthSubRoute.resetOtp;
    _resetEmail = email;
    notifyListeners();
  }

  void navigateToNewPassword(String email, String otp) {
    _authSubRoute = AuthSubRoute.newPassword;
    _resetEmail = email;
    _resetOtp = otp;
    notifyListeners();
  }

  // ── Build page stack ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: _buildPages(),
      onDidRemovePage: (page) {
        // When a page is removed (popped), reset to auth landing
        // if we were showing login or signup.
        if (_authSubRoute != AuthSubRoute.landing) {
          _authSubRoute = AuthSubRoute.landing;
          notifyListeners();
        }
      },
    );
  }

  List<Page<dynamic>> _buildPages() {
    // ── Authenticated → Home (no auth screens in stack) ───────────────
    if (authProvider.authStatus == AuthStatus.authenticated) {
      // Reset sub-route so re-logout starts at landing.
      _authSubRoute = AuthSubRoute.landing;
      return [
        const MaterialPage(
          key: ValueKey('home'),
          child: HomeScreen(),
        ),
      ];
    }

    // Both Loading & Unauthenticated share the base auth screen.
    return [
      // Base: Auth landing screen (always in stack)
      MaterialPage(
        key: const ValueKey('auth_base'),
        child: AuthScreen(routerDelegate: this),
      ),
      // Optionally push login or signup on top if unauthenticated
      if (authProvider.authStatus == AuthStatus.unauthenticated && _authSubRoute == AuthSubRoute.login)
        MaterialPage(
          key: const ValueKey('login'),
          child: LoginScreen(routerDelegate: this),
        ),
      if (authProvider.authStatus == AuthStatus.unauthenticated && _authSubRoute == AuthSubRoute.signup)
        MaterialPage(
          key: const ValueKey('signup'),
          child: SignupScreen(routerDelegate: this),
        ),
      if (authProvider.authStatus == AuthStatus.unauthenticated && _authSubRoute == AuthSubRoute.otp && _otpEmail != null)
        MaterialPage(
          key: const ValueKey('otp'),
          child: OtpScreen(routerDelegate: this, email: _otpEmail!),
        ),
      if (authProvider.authStatus == AuthStatus.unauthenticated && _authSubRoute == AuthSubRoute.forgotPassword)
        MaterialPage(
          key: const ValueKey('forgot_password'),
          child: ForgotPasswordScreen(routerDelegate: this),
        ),
      if (authProvider.authStatus == AuthStatus.unauthenticated && _authSubRoute == AuthSubRoute.resetOtp && _resetEmail != null)
        MaterialPage(
          key: const ValueKey('reset_otp'),
          child: ResetOtpScreen(routerDelegate: this, email: _resetEmail!),
        ),
      if (authProvider.authStatus == AuthStatus.unauthenticated && _authSubRoute == AuthSubRoute.newPassword && _resetEmail != null && _resetOtp != null)
        MaterialPage(
          key: const ValueKey('new_password'),
          child: NewPasswordScreen(
            routerDelegate: this,
            email: _resetEmail!,
            otp: _resetOtp!,
          ),
        ),
    ];
  }

  // ── Required overrides ────────────────────────────────────────────────
  @override
  Future<void> setNewRoutePath(RouteInformation configuration) async {
    // Navigation is state-driven; URL changes are ignored.
  }

  @override
  void dispose() {
    authProvider.removeListener(notifyListeners);
    super.dispose();
  }
}
