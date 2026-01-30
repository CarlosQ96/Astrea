import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/astrea_colors.dart';

/// A particle for the dissolution effect.
class _Particle {
  Offset position;
  Offset velocity;
  double size;
  double opacity;
  Color color;
  double wobbleOffset; // For organic drift
  double wobbleSpeed; // Unique wobble frequency

  _Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.opacity,
    required this.color,
    required this.wobbleOffset,
    required this.wobbleSpeed,
  });
}

/// A widget that dissolves into particles when triggered.
class ParticleDissolve extends StatefulWidget {
  final Widget child;
  final bool dissolve;
  final VoidCallback? onDissolveComplete;
  final Duration duration;
  final int particleCount;

  const ParticleDissolve({
    super.key,
    required this.child,
    required this.dissolve,
    this.onDissolveComplete,
    this.duration = const Duration(milliseconds: 1200),
    this.particleCount = 40,
  });

  @override
  State<ParticleDissolve> createState() => _ParticleDissolveState();
}

class _ParticleDissolveState extends State<ParticleDissolve>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _particleAnimation;

  final List<_Particle> _particles = [];
  final Random _random = Random();
  final GlobalKey _childKey = GlobalKey();
  bool _showParticles = false;
  bool _dissolveTriggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDissolveComplete?.call();
      }
    });

    // Check if already dissolving on init
    if (widget.dissolve) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startDissolve();
      });
    }
  }

  @override
  void didUpdateWidget(ParticleDissolve oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dissolve && !_dissolveTriggered) {
      _startDissolve();
    }
  }

  void _startDissolve() {
    if (_dissolveTriggered) return;
    _dissolveTriggered = true;

    // Get size from the child's render box
    final RenderBox? box =
        _childKey.currentContext?.findRenderObject() as RenderBox?;
    final size = box?.size ?? const Size(200, 60);

    _particles.clear();
    _generateParticles(size);
    setState(() => _showParticles = true);
    _controller.forward(from: 0);
  }

  void _generateParticles(Size size) {
    final colors = [
      AstreaColors.starlightCyan,
      AstreaColors.glowTeal,
      AstreaColors.mysticViolet,
      AstreaColors.oracleLavender,
    ];

    for (int i = 0; i < widget.particleCount; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;

      // Slower, more subtle movement
      final vx = (_random.nextDouble() - 0.5) * 80;
      final vy = -_random.nextDouble() * 60 - 20;

      _particles.add(
        _Particle(
          position: Offset(x, y),
          velocity: Offset(vx, vy),
          size: _random.nextDouble() * 5 + 2,
          opacity: _random.nextDouble() * 0.3 + 0.7,
          color: colors[_random.nextInt(colors.length)],
          wobbleOffset: _random.nextDouble() * 3.14159 * 2, // Random phase
          wobbleSpeed: _random.nextDouble() * 2 + 1, // Unique frequency
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Original child with fade
        AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: widget.dissolve ? _fadeAnimation.value : 1.0,
              child: Transform.scale(
                scale: widget.dissolve
                    ? lerpDouble(1.0, 0.9, 1 - _fadeAnimation.value)!
                    : 1.0,
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: _childKey,
            child: widget.child,
          ),
        ),

        // Particles overlay
        if (_showParticles)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _particleAnimation,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ParticlePainter(
                      particles: _particles,
                      progress: _particleAnimation.value,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// Paints the particles.
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Use eased progress for smoother movement
    final easedProgress = Curves.easeOutCubic.transform(progress);

    for (final particle in particles) {
      // Add sine-wave wobble for organic drift
      final wobble =
          sin(
            particle.wobbleOffset + progress * particle.wobbleSpeed * 3.14159,
          ) *
          8;

      final currentPos = Offset(
        particle.position.dx + particle.velocity.dx * easedProgress + wobble,
        particle.position.dy + particle.velocity.dy * easedProgress,
      );

      // Smooth fade out with easing
      final fadeProgress = Curves.easeInQuad.transform(progress);
      final opacity = particle.opacity * (1 - fadeProgress);
      if (opacity <= 0) continue;

      // Gentle size reduction
      final currentSize = particle.size * (1 - easedProgress * 0.3);

      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.5 + easedProgress);

      canvas.drawCircle(currentPos, currentSize, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
