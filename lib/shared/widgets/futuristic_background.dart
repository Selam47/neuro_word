import 'dart:math';
import 'package:flutter/material.dart';
import 'package:neuro_word/core/constants/app_colors.dart';

/// A reusable animated deep-space background with subtle neon gradients
/// and floating particle effect that sits behind all screens.
class FuturisticBackground extends StatelessWidget {
  const FuturisticBackground({
    super.key,
    required this.child,
    this.showParticles = true,
    this.overlayOpacity = 0.0,
  });

  final Widget child;
  final bool showParticles;
  final double overlayOpacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Base gradient ────────────────────────────────────────
        const _BaseGradient(),

        // ── Subtle radial glow spots ─────────────────────────────
        const _NeonGlowSpots(),

        // ── Animated floating particles ──────────────────────────
        if (showParticles) const _FloatingParticles(),

        // ── Grid overlay for HUD feel ────────────────────────────
        const _GridOverlay(),

        // ── Optional dark overlay (for modals / focus) ───────────
        if (overlayOpacity > 0)
          Container(color: AppColors.deepSpace.withValues(alpha: overlayOpacity)),

        // ── Content ──────────────────────────────────────────────
        child,
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Private sub-widgets
// ═══════════════════════════════════════════════════════════════════════

class _BaseGradient extends StatelessWidget {
  const _BaseGradient();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deepSpace,
            Color(0xFF0D1117),
            Color(0xFF0F1923),
            AppColors.deepSpace,
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
    );
  }
}

class _NeonGlowSpots extends StatelessWidget {
  const _NeonGlowSpots();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top-right electric blue glow
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.electricBlue.withValues(alpha: 0.08),
                  AppColors.electricBlue.withValues(alpha: 0.02),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Bottom-left cyber purple glow
        Positioned(
          bottom: -100,
          left: -80,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.cyberPurple.withValues(alpha: 0.06),
                  AppColors.cyberPurple.withValues(alpha: 0.02),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Centre subtle highlight
        Positioned(
          top: MediaQuery.sizeOf(context).height * 0.3,
          left: MediaQuery.sizeOf(context).width * 0.2,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.electricBlue.withValues(alpha: 0.03),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FloatingParticles extends StatefulWidget {
  const _FloatingParticles();

  @override
  State<_FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<_FloatingParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    final random = Random(42);
    _particles = List.generate(
      30,
      (_) => _Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 1.0 + random.nextDouble() * 2.0,
        speed: 0.2 + random.nextDouble() * 0.6,
        opacity: 0.15 + random.nextDouble() * 0.35,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(
            particles: _particles,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });

  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.particles, required this.progress});

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dy = (p.y + progress * p.speed) % 1.0;
      final dx = p.x + sin(progress * pi * 2 * p.speed) * 0.02;

      canvas.drawCircle(
        Offset(dx * size.width, dy * size.height),
        p.size,
        Paint()
          ..color = AppColors.electricBlue.withValues(alpha: p.opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _GridOverlay extends StatelessWidget {
  const _GridOverlay();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.03,
      child: CustomPaint(size: Size.infinite, painter: _GridPainter()),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.electricBlue
      ..strokeWidth = 0.5;

    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

