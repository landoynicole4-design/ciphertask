import 'package:flutter/material.dart';
import 'dart:math' as math;

/// CipherTransitions — Drop-in page transitions for CipherTask.
///
/// HOW TO USE:
///
/// Option A — Named routes (replace pushNamed with pushNamedCipher):
///   Navigator.of(context).pushNamedCipher('/login');       // glitch slide
///   Navigator.of(context).pushNamedCipher('/register', style: CipherTransitionStyle.fadeScale);
///
/// Option B — Direct route push:
///   Navigator.push(context, CipherPageRoute(page: const LoginView()));
///   Navigator.push(context, CipherPageRoute(page: const RegisterView(), style: CipherTransitionStyle.glitch));
///
/// Option C — In your MaterialApp onGenerateRoute:
///   onGenerateRoute: (settings) => CipherRouteFactory.generate(settings),

// ── Transition styles ────────────────────────────────────────────────
enum CipherTransitionStyle {
  /// Slides up with a glitch flash — used for Login → Dashboard
  glitchSlideUp,

  /// Fades + scales in — used for modals, register
  fadeScale,

  /// Slides in from the right with a teal shimmer
  shimmerSlideRight,

  /// Reveals from center with expanding circle clip
  circularReveal,
}

// ── Custom PageRoute ─────────────────────────────────────────────────
class CipherPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final CipherTransitionStyle style;

  CipherPageRoute({
    required this.page,
    this.style = CipherTransitionStyle.glitchSlideUp,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 520),
          reverseTransitionDuration: const Duration(milliseconds: 380),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildTransition(
                style, animation, secondaryAnimation, child);
          },
        );

  static Widget _buildTransition(
    CipherTransitionStyle style,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    switch (style) {
      case CipherTransitionStyle.glitchSlideUp:
        return _GlitchSlideTransition(animation: animation, child: child);
      case CipherTransitionStyle.fadeScale:
        return _FadeScaleTransition(animation: animation, child: child);
      case CipherTransitionStyle.shimmerSlideRight:
        return _ShimmerSlideTransition(animation: animation, child: child);
      case CipherTransitionStyle.circularReveal:
        return _CircularRevealTransition(animation: animation, child: child);
    }
  }
}

// ── Glitch Slide Up ──────────────────────────────────────────────────
/// Screen slides up with scanline artifacts at start — signature transition
class _GlitchSlideTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _GlitchSlideTransition({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
    ));

    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    final glitchOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );

    return Stack(
      children: [
        // Glitch flash overlay (teal scanlines at start)
        FadeTransition(
          opacity: glitchOpacity,
          child: Container(
            color: const Color(0xFF050810),
            child: AnimatedBuilder(
              animation: animation,
              builder: (_, __) => CustomPaint(
                painter: _GlitchOverlayPainter(animation.value),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        // Main page
        FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        ),
      ],
    );
  }
}

// ── Fade Scale ───────────────────────────────────────────────────────
class _FadeScaleTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _FadeScaleTransition({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
    );
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);

    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(scale: scale, child: child),
    );
  }
}

// ── Shimmer Slide Right ──────────────────────────────────────────────
class _ShimmerSlideTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _ShimmerSlideTransition({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    final slide = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    final shimmerOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
    );

    return Stack(
      children: [
        // Shimmer leading edge
        FadeTransition(
          opacity: shimmerOpacity,
          child: AnimatedBuilder(
            animation: animation,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1 + animation.value * 3, 0),
                  end: Alignment(-0.5 + animation.value * 3, 0),
                  colors: [
                    const Color(0xFF00F5D4).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        ),
      ],
    );
  }
}

// ── Circular Reveal ──────────────────────────────────────────────────
class _CircularRevealTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _CircularRevealTransition(
      {required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return ClipPath(
          clipper: _CircleRevealClipper(animation.value),
          child: child,
        );
      },
    );
  }
}

class _CircleRevealClipper extends CustomClipper<Path> {
  final double progress;
  _CircleRevealClipper(this.progress);

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height) / 2;
    final curve = Curves.easeOutCubic.transform(progress);
    final radius = maxRadius * curve;

    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_CircleRevealClipper old) => old.progress != progress;
}

// ── Glitch overlay painter ───────────────────────────────────────────
class _GlitchOverlayPainter extends CustomPainter {
  final double t;
  _GlitchOverlayPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (t > 0.25) return;
    final intensity = (1.0 - (t / 0.25)).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = const Color(0xFF00F5D4).withValues(alpha: 0.04 * intensity);

    // Horizontal scanlines
    final rand = math.Random(42);
    for (int i = 0; i < 8; i++) {
      final y = rand.nextDouble() * size.height;
      final h = 1.0 + rand.nextDouble() * 3;
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, h), paint);
    }

    // Vertical displacement bars
    final barPaint = Paint()
      ..color = const Color(0xFF7B61FF).withValues(alpha: 0.06 * intensity);
    for (int i = 0; i < 3; i++) {
      final x = rand.nextDouble() * size.width;
      canvas.drawRect(Rect.fromLTWH(x, 0, 2, size.height), barPaint);
    }
  }

  @override
  bool shouldRepaint(_GlitchOverlayPainter old) => old.t != t;
}

// ── Navigator extension ──────────────────────────────────────────────
/// Adds convenient pushNamedCipher and pushReplacementNamedCipher methods.
extension CipherNavigator on NavigatorState {
  Future<T?> pushCipher<T>(
    Widget page, {
    CipherTransitionStyle style = CipherTransitionStyle.glitchSlideUp,
  }) {
    return push(CipherPageRoute<T>(page: page, style: style));
  }

  Future<T?> pushReplacementCipher<T, TO>(
    Widget page, {
    CipherTransitionStyle style = CipherTransitionStyle.glitchSlideUp,
    TO? result,
  }) {
    return pushReplacement(
      CipherPageRoute<T>(page: page, style: style),
      result: result,
    );
  }
}

// ── Route factory for onGenerateRoute ───────────────────────────────
/// Map your route names to transition styles here.
///
/// Usage in MaterialApp:
///   onGenerateRoute: CipherRouteFactory.generate,
class CipherRouteFactory {
  /// Map route names → (widget builder, transition style)
  static final _routes = <String, (WidgetBuilder, CipherTransitionStyle)>{};

  /// Register your routes:
  ///   CipherRouteFactory.register('/login', (_) => const LoginView());
  ///   CipherRouteFactory.register('/register', (_) => const RegisterView(),
  ///       style: CipherTransitionStyle.fadeScale);
  static void register(
    String name,
    WidgetBuilder builder, {
    CipherTransitionStyle style = CipherTransitionStyle.glitchSlideUp,
  }) {
    _routes[name] = (builder, style);
  }

  static Route<dynamic>? generate(RouteSettings settings) {
    final entry = _routes[settings.name];
    if (entry == null) return null;
    final (builder, style) = entry;
    return CipherPageRoute(
      page: Builder(builder: builder),
      style: style,
      settings: settings,
    );
  }
}
