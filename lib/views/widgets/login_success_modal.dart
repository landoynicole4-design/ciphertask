import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/constants.dart';

/// LoginSuccessModal — Premium success overlay after authentication
class LoginSuccessModal extends StatefulWidget {
  final String email;
  final bool isBiometric;

  const LoginSuccessModal({
    super.key,
    this.email = '',
    this.isBiometric = false,
  });

  static Future<void> show(
    BuildContext context, {
    String email = '',
    bool isBiometric = false,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => LoginSuccessModal(email: email, isBiometric: isBiometric),
    );
  }

  @override
  State<LoginSuccessModal> createState() => _LoginSuccessModalState();
}

class _LoginSuccessModalState extends State<LoginSuccessModal>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _checkController;
  late AnimationController _particleController;
  late AnimationController _progressController;

  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  static const int _autoDismissMs = 2800;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim =
        CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _autoDismissMs),
    );

    _fadeController.forward().then((_) {
      _scaleController.forward().then((_) {
        _checkController.forward();
        _particleController.forward();
        _progressController.forward().then((_) => _navigate());
      });
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _checkController.dispose();
    _particleController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.of(context).pop();
    Navigator.pushReplacementNamed(context, AppConstants.todoListRoute);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Fix: more horizontal padding so card never touches screen edges
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: _buildCard(),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      // Fix: constrain max width so it looks good on tablets too
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1020),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF4ADE80).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ADE80).withValues(alpha: 0.12),
            blurRadius: 40,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: const Color(0xFF00F5D4).withValues(alpha: 0.08),
            blurRadius: 60,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSuccessIcon(),
          const SizedBox(height: 20),
          _buildTitle(),
          const SizedBox(height: 8),
          _buildSubtitle(),
          const SizedBox(height: 24),
          _buildSecurityBadges(),
          const SizedBox(height: 24),
          _buildProgressButton(),
        ],
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return AnimatedBuilder(
      animation: Listenable.merge([_particleController, _checkController]),
      builder: (context, _) {
        return SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ..._buildParticles(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF4ADE80).withValues(
                        alpha: 0.3 + _particleController.value * 0.2),
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4ADE80), Color(0xFF00F5D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4ADE80).withValues(alpha: 0.4),
                      blurRadius: 20 + _particleController.value * 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: widget.isBiometric
                    ? const Icon(Icons.fingerprint_rounded,
                        color: Colors.white, size: 40)
                    : CustomPaint(
                        painter: _CheckPainter(_checkController.value),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildParticles() {
    if (_particleController.value < 0.1) return [];
    final t = _particleController.value;
    final results = <Widget>[];
    const count = 8;
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi;
      final dist = 55.0 * t;
      final opacity = (1.0 - t).clamp(0.0, 1.0);
      final dx = math.cos(angle) * dist;
      final dy = math.sin(angle) * dist;
      results.add(
        Positioned(
          left: 55 + dx - 4,
          top: 55 + dy - 4,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i % 2 == 0
                    ? const Color(0xFF4ADE80)
                    : const Color(0xFF00F5D4),
              ),
            ),
          ),
        ),
      );
    }
    return results;
  }

  Widget _buildTitle() {
    return Text(
      widget.isBiometric ? 'Biometric Verified!' : 'Login Successful!',
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Column(
      children: [
        Text(
          widget.isBiometric
              ? 'Identity confirmed via biometrics'
              : 'Welcome back to CipherTask',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 14,
          ),
        ),
        if (widget.email.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF00F5D4).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF00F5D4).withValues(alpha: 0.2)),
            ),
            child: Text(
              widget.email,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Color(0xFF00F5D4),
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSecurityBadges() {
    // Fix: use Wrap so badges never overflow — they flow to next line if needed
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _badge(Icons.lock_rounded, 'AES-256', const Color(0xFF7B61FF)),
        _badge(Icons.shield_rounded, 'Encrypted', const Color(0xFF00F5D4)),
        _badge(Icons.verified_rounded, 'Secure', const Color(0xFF4ADE80)),
      ],
    );
  }

  Widget _badge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressButton() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (_, __) {
        return GestureDetector(
          onTap: _navigate,
          child: Container(
            height: 52,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF4ADE80), Color(0xFF00F5D4)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4ADE80).withValues(alpha: 0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 1.0 - _progressController.value,
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.rocket_launch_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          "Let's Go",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  _CheckPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    final p1 = Offset(cx - 14, cy + 2);
    final p2 = Offset(cx - 3, cy + 13);
    final p3 = Offset(cx + 16, cy - 12);

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy);

    final metrics = path.computeMetrics().first;
    final drawn = metrics.extractPath(0, metrics.length * progress);
    canvas.drawPath(drawn, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}
