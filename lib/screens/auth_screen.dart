import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../router/app_router_delegate.dart';

/// Auth landing screen — Deezer-accurate UI with modern typography.
class AuthScreen extends StatefulWidget {
  final AppRouterDelegate routerDelegate;

  const AuthScreen({super.key, required this.routerDelegate});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  // Reusable Caveat text style helper
  TextStyle _caveat({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    Color color = Colors.white,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return TextStyle(
      fontFamily: 'Caveat',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Base Background (Purple / Accent) ──────────────────────────────
          Container(
            color: AppTheme.accent,
            width: double.infinity,
            height: double.infinity,
          ),

          // ── Black Wavy Shape ───────────────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _BlackWavesPainter(_waveController.value),
                );
              },
            ),
          ),

          // ── Content ────────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Push content down into the black area
                  SizedBox(height: size.height * 0.30),

                  // ── Title ───────────────────────────────────────────────────
                  Text(
                    'WELCOME TO\nMUSICROOM',
                    style: _caveat(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Subtitle ────────────────────────────────────────────────
                  RichText(
                    text: TextSpan(
                      style: _caveat(
                        color: AppTheme.textSecondary,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: 'Sign up for free or '),
                        TextSpan(
                          text: 'log in',
                          style: _caveat(
                            color: Colors.white,
                            fontSize: 28, // Make it bigger
                            fontWeight: FontWeight.w800, // Make it a bit bolder
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => widget.routerDelegate.navigateToLogin(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── Primary CTA: Continue with email ───────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => widget.routerDelegate.navigateToSignup(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Continue with email',
                        style: _caveat(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── 'or' separator ─────────────────────────────────────────
                  Center(
                    child: Text(
                      'or',
                      style: _caveat(
                        color: AppTheme.textSecondary,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Google Sign-In Button (full-width, outlined) ────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: trigger Google sign-in
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: AppTheme.textSecondary.withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google "G" logo — clean SVG-style painted version
                          _GoogleLogo(size: 22),
                          const SizedBox(width: 12),
                          Text(
                            'Continue with Google',
                            style: _caveat(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // ── Footer: Partner offer ──────────────────────────────────
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: GestureDetector(
                        onTap: () {},
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Activate my partner offer',
                              style: _caveat(
                                color: AppTheme.textSecondary,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: AppTheme.textSecondary,
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Google "G" logo rendered via CustomPaint (no asset needed)
// ─────────────────────────────────────────────────────────────────────────────
class _GoogleLogo extends StatelessWidget {
  final double size;
  const _GoogleLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    // Clip to circle
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)));

    // White background
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = Colors.white);

    // Arcs — simplified four-color Google G
    final segments = [
      (0.0, 0.5 * 3.14159, const Color(0xFF4285F4)),   // Blue top-right
      (0.5 * 3.14159, 0.5 * 3.14159, const Color(0xFF34A853)), // Green bottom-right
      (1.0 * 3.14159, 0.5 * 3.14159, const Color(0xFFFBBC05)), // Yellow bottom-left
      (1.5 * 3.14159, 0.5 * 3.14159, const Color(0xFFEA4335)), // Red top-left
    ];

    for (final seg in segments) {
      final paint = Paint()
        ..color = seg.$3
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.38;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.62),
        seg.$1,
        seg.$2,
        false,
        paint,
      );
    }

    // White inner circle cutout
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.43,
      Paint()..color = Colors.white,
    );

    // Blue horizontal bar (right arm of G)
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.1, r * 0.7, r * 0.2),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Black wavy background shape
// ─────────────────────────────────────────────────────────────────────────────
class _BlackWavesPainter extends CustomPainter {
  final double animationValue;

  _BlackWavesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.background;
    final path = Path();

    final t = animationValue * 2 * pi;
    final dy = size.height * 0.015; // Vertical sway
    final dx = size.width * 0.02;   // Horizontal sway

    path.moveTo(0, size.height);
    path.lineTo(size.width, size.height);
    
    // Right edge
    path.lineTo(size.width, size.height * 0.30 + sin(t) * dy);

    // Peak 3 (Right)
    path.quadraticBezierTo(
      size.width * 0.85 + cos(t) * dx, size.height * 0.14 + sin(t + 1) * dy,
      size.width * 0.72 + cos(t + 1) * dx, size.height * 0.26 + sin(t + 2) * dy,
    );

    // Peak 2 (Middle)
    path.quadraticBezierTo(
      size.width * 0.52 + cos(t + 2) * dx, size.height * 0.06 + sin(t + 3) * dy,
      size.width * 0.38 + cos(t + 3) * dx, size.height * 0.28 + sin(t + 4) * dy,
    );

    // Peak 1 (Left)
    path.quadraticBezierTo(
      size.width * 0.14 + cos(t + 4) * dx, size.height * 0.00 + sin(t + 5) * dy,
      0, size.height * 0.16 + sin(t + 6) * dy,
    );

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BlackWavesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}