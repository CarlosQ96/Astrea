import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/astrea_colors.dart';

/// A star in the constellation with drift movement.
/// Positions stored as normalized (0-1) to avoid stretching on resize.
class _Star {
  double normalizedX; // 0-1 position
  double normalizedY; // 0-1 position
  double size;
  double baseOpacity;
  double twinkleSpeed;
  double twinkleOffset;
  double driftRadius;
  double driftSpeed;
  double driftOffset;
  bool isConstellation;

  _Star({
    required this.normalizedX,
    required this.normalizedY,
    required this.size,
    required this.baseOpacity,
    required this.twinkleSpeed,
    required this.twinkleOffset,
    required this.driftRadius,
    required this.driftSpeed,
    required this.driftOffset,
    this.isConstellation = false,
  });

  Offset getPosition(double time, Size canvasSize) {
    final baseX = normalizedX * canvasSize.width;
    final baseY = normalizedY * canvasSize.height;
    final driftX = cos(time * pi * 2 * driftSpeed + driftOffset) * driftRadius;
    final driftY =
        sin(time * pi * 2 * driftSpeed + driftOffset * 1.3) * driftRadius * 0.6;
    return Offset(baseX + driftX, baseY + driftY);
  }
}

/// A floating particle with organic movement.
class _Particle {
  double normalizedX;
  double normalizedY;
  double size;
  double baseOpacity;
  Color color;
  double floatSpeed;
  double wobbleSpeed;
  double wobbleAmount;
  double phaseOffset;
  double verticalRange;

  _Particle({
    required this.normalizedX,
    required this.normalizedY,
    required this.size,
    required this.baseOpacity,
    required this.color,
    required this.floatSpeed,
    required this.wobbleSpeed,
    required this.wobbleAmount,
    required this.phaseOffset,
    required this.verticalRange,
  });

  Offset getPosition(double time, Size canvasSize) {
    final baseX = normalizedX * canvasSize.width;
    final baseY = normalizedY * canvasSize.height;
    final verticalOffset =
        sin(time * pi * 2 * floatSpeed + phaseOffset) * verticalRange;
    final wobble =
        sin(time * pi * 2 * wobbleSpeed + phaseOffset * 1.7) * wobbleAmount;
    return Offset(baseX + wobble, baseY + verticalOffset);
  }

  double getOpacity(double time) {
    final pulse =
        sin(time * pi * 2 * floatSpeed * 0.7 + phaseOffset) * 0.3 + 0.7;
    return (baseOpacity * pulse).clamp(0.1, 0.8);
  }
}

/// Virgo constellation star positions (normalized 0-1)
const _virgoPattern = [
  Offset(0.15, 0.3), // Zavijava
  Offset(0.25, 0.45), // Porrima
  Offset(0.35, 0.35), // Auva
  Offset(0.45, 0.5), // Vindemiatrix
  Offset(0.55, 0.4), // Spica (brightest)
  Offset(0.65, 0.55),
  Offset(0.75, 0.45),
  Offset(0.85, 0.6),
  Offset(0.5, 0.25), // Upper branch
  Offset(0.6, 0.2),
];

/// Connections between Virgo stars (indices)
const _virgoConnections = [
  [0, 1],
  [1, 2],
  [2, 3],
  [3, 4],
  [4, 5],
  [5, 6],
  [6, 7],
  [3, 8],
  [8, 9],
];

class ConstellationBackground extends StatefulWidget {
  final int starCount;
  final int particleCount;

  const ConstellationBackground({
    super.key,
    this.starCount = 40,
    this.particleCount = 25,
  });

  @override
  State<ConstellationBackground> createState() =>
      _ConstellationBackgroundState();
}

class _ConstellationBackgroundState extends State<ConstellationBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Star> _stars = [];
  final List<_Star> _virgoStars = [];
  final List<_Particle> _particles = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Continuous animation without reverse for smooth looping
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat(); // No reverse - continuous forward movement
    _generateStars();
  }

  void _generateStars() {
    if (_initialized) return;
    _initialized = true;

    // Use fixed seed for consistent positions
    final random = Random(42);

    // Top padding as normalized value
    const topPadding = 0.03;

    // Generate Virgo constellation stars (in top portion)
    for (int i = 0; i < _virgoPattern.length; i++) {
      final pos = _virgoPattern[i];
      final isBright = i == 4; // Spica is brightest
      // Scale Virgo to top portion of the area
      _virgoStars.add(
        _Star(
          normalizedX: pos.dx,
          normalizedY: topPadding + pos.dy * 0.38,
          size: isBright ? 2.5 : 1.8,
          baseOpacity: isBright ? 0.95 : 0.8,
          twinkleSpeed: random.nextDouble() * 0.8 + 0.3,
          twinkleOffset: random.nextDouble() * pi * 2,
          driftRadius: 4,
          driftSpeed: 0.15,
          driftOffset: random.nextDouble() * pi * 2,
          isConstellation: true,
        ),
      );
    }

    // Generate background stars (spread across full area)
    for (int i = 0; i < widget.starCount; i++) {
      _stars.add(
        _Star(
          normalizedX: random.nextDouble(),
          normalizedY: topPadding + random.nextDouble() * (1 - topPadding),
          size: random.nextDouble() * 1.2 + 0.3,
          baseOpacity: random.nextDouble() * 0.4 + 0.2,
          twinkleSpeed: random.nextDouble() * 1.5 + 0.3,
          twinkleOffset: random.nextDouble() * pi * 2,
          driftRadius: random.nextDouble() * 8 + 3,
          driftSpeed: random.nextDouble() * 0.4 + 0.1,
          driftOffset: random.nextDouble() * pi * 2,
        ),
      );
    }

    // Generate floating particles
    final particleColors = [
      AstreaColors.starlightCyan,
      AstreaColors.mysticViolet,
      AstreaColors.oracleLavender,
      AstreaColors.starWhite,
    ];

    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(
        _Particle(
          normalizedX: random.nextDouble(),
          normalizedY: topPadding + random.nextDouble() * (1 - topPadding),
          size: random.nextDouble() * 3 + 1.5,
          baseOpacity: random.nextDouble() * 0.4 + 0.2,
          color: particleColors[random.nextInt(particleColors.length)],
          floatSpeed: random.nextDouble() * 0.3 + 0.1,
          wobbleSpeed: random.nextDouble() * 0.5 + 0.2,
          wobbleAmount: random.nextDouble() * 15 + 5,
          phaseOffset: random.nextDouble() * pi * 2,
          verticalRange: random.nextDouble() * 20 + 10,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              size: size,
              painter: _ConstellationPainter(
                stars: _stars,
                virgoStars: _virgoStars,
                particles: _particles,
                time: _controller.value,
              ),
            );
          },
        );
      },
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  final List<_Star> stars;
  final List<_Star> virgoStars;
  final List<_Particle> particles;
  final double time;

  _ConstellationPainter({
    required this.stars,
    required this.virgoStars,
    required this.particles,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw floating particles first (behind everything)
    for (final particle in particles) {
      final pos = particle.getPosition(time, size);
      final opacity = particle.getOpacity(time);

      // Soft glow
      final glowPaint = Paint()
        ..color = particle.color.withAlpha((opacity * 0.4 * 255).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(pos, particle.size * 2.5, glowPaint);

      // Particle core
      final corePaint = Paint()
        ..color = particle.color.withAlpha((opacity * 255).round());
      canvas.drawCircle(pos, particle.size, corePaint);
    }

    // Draw background stars
    for (final star in stars) {
      final pos = star.getPosition(time, size);
      final twinkle = sin(
        time * pi * 2 * star.twinkleSpeed + star.twinkleOffset,
      );
      final opacity = (star.baseOpacity + twinkle * 0.2).clamp(0.1, 0.7);

      // Subtle glow
      final glowPaint = Paint()
        ..color = AstreaColors.starlightCyan.withAlpha(
          (opacity * 0.3 * 255).round(),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(pos, star.size * 3, glowPaint);

      // Star core
      final starPaint = Paint()
        ..color = AstreaColors.starWhite.withAlpha((opacity * 255).round());
      canvas.drawCircle(pos, star.size, starPaint);
    }

    // Get Virgo positions
    final virgoPositions = virgoStars
        .map((s) => s.getPosition(time, size))
        .toList();

    // Draw Virgo constellation lines
    final linePaint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final connection in _virgoConnections) {
      final start = virgoPositions[connection[0]];
      final end = virgoPositions[connection[1]];

      // Gradient line effect
      final lineOpacity = 0.25 + sin(time * pi * 2 * 0.5) * 0.1;
      linePaint.color = AstreaColors.mysticViolet.withAlpha(
        (lineOpacity * 255).round(),
      );
      canvas.drawLine(start, end, linePaint);

      // Subtle glow on line
      final glowLinePaint = Paint()
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..color = AstreaColors.mysticViolet.withAlpha(
          (lineOpacity * 0.3 * 255).round(),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawLine(start, end, glowLinePaint);
    }

    // Draw Virgo constellation stars (brighter)
    for (int i = 0; i < virgoStars.length; i++) {
      final star = virgoStars[i];
      final pos = virgoPositions[i];
      final twinkle = sin(
        time * pi * 2 * star.twinkleSpeed + star.twinkleOffset,
      );
      final opacity = (star.baseOpacity + twinkle * 0.15).clamp(0.6, 1.0);

      // Outer glow - larger and more visible
      final outerGlow = Paint()
        ..color = AstreaColors.starlightCyan.withAlpha(
          (opacity * 0.2 * 255).round(),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(pos, star.size * 6, outerGlow);

      // Inner glow
      final innerGlow = Paint()
        ..color = AstreaColors.starlightCyan.withAlpha(
          (opacity * 0.5 * 255).round(),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(pos, star.size * 3, innerGlow);

      // Star body - cyan tint
      final bodyPaint = Paint()
        ..color = AstreaColors.starlightCyan.withAlpha((opacity * 255).round());
      canvas.drawCircle(pos, star.size * 1.2, bodyPaint);

      // Bright white core - crisp
      final corePaint = Paint()
        ..color = AstreaColors.starWhite.withAlpha((opacity * 255).round());
      canvas.drawCircle(pos, star.size * 0.6, corePaint);
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
