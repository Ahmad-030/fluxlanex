import 'dart:math';
import 'package:flutter/material.dart';
import 'game_controller.dart';
import 'game_constants.dart';
import 'obstacle.dart';
import 'particle_system.dart';
import '../utils/app_theme.dart';

class GamePainter extends CustomPainter {
  final GameController ctrl;

  GamePainter(this.ctrl) : super(repaint: ctrl);

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawLanes(canvas, size);
    _drawObstacles(canvas, size);
    _drawTrail(canvas);
    _drawPlayer(canvas);
    _drawParticles(canvas, size);
  }

  // ── Background ─────────────────────────────────────────────────────────────

  void _drawBackground(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppTheme.laneLineColor.withOpacity(0.5)
      ..strokeWidth = 1.0;

    final offset = ctrl.bgOffset;
    for (double y = -80 + offset; y < size.height + 80; y += 80) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (ctrl.fluxMode) {
      final shimmer = Paint()
        ..shader = LinearGradient(
          colors: [
            AppTheme.neonCyan.withOpacity(0.06),
            Colors.transparent,
            AppTheme.neonCyan.withOpacity(0.06),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), shimmer);
    }
  }

  // ── Lane dividers ──────────────────────────────────────────────────────────

  void _drawLanes(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppTheme.laneLineColor
      ..strokeWidth = 1.5;

    final lw = ctrl.laneWidth;
    canvas.drawLine(
      Offset(lw + ctrl.fluxLaneOffset, 0),
      Offset(lw + ctrl.fluxLaneOffset, size.height),
      linePaint,
    );
    canvas.drawLine(
      Offset(lw * 2 - ctrl.fluxLaneOffset, 0),
      Offset(lw * 2 - ctrl.fluxLaneOffset, size.height),
      linePaint,
    );
  }

  // ── Obstacles ──────────────────────────────────────────────────────────────

  void _drawObstacles(Canvas canvas, Size size) {
    for (final obs in ctrl.obstacles) {
      if (obs.y < -obs.height || obs.y > size.height + 20) continue;
      _drawObstacle(canvas, obs);
    }
  }

  void _drawObstacle(Canvas canvas, Obstacle obs) {
    final lw = ctrl.laneWidth;
    double ox;

    if (obs.type == ObstacleType.flashWall) {
      ox = lw * obs.flashStartLane;
    } else {
      ox = lw * obs.lane + (lw - obs.width) / 2;
    }

    final oy = obs.y;
    double ow =
    obs.type == ObstacleType.flashWall ? lw * obs.flashSpan : obs.width;
    double oh = obs.height;

    Color mainColor;
    Color glowColor;
    double radius = 8;

    switch (obs.type) {
      case ObstacleType.staticBlock:
        mainColor = AppTheme.obstacleRed;
        glowColor = AppTheme.obstacleRed.withOpacity(0.35);
        break;
      case ObstacleType.fluxBlock:
        mainColor = AppTheme.fluxOrange;
        glowColor = AppTheme.fluxOrange.withOpacity(0.4);
        radius = 10;
        break;
      case ObstacleType.pulseBar:
        mainColor = AppTheme.pulsePurple;
        glowColor = AppTheme.pulsePurple.withOpacity(0.4);
        ow *= obs.pulseScale;
        oh *= obs.pulseScale;
        ox = lw * obs.lane + (lw - ow) / 2;
        radius = 4;
        break;
      case ObstacleType.flashWall:
        mainColor = const Color(0xFFFF2D55);
        glowColor = const Color(0x55FF2D55);
        radius = 6;
        break;
    }

    // Glow
    final glowPaint = Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(ox - 4, oy - 4, ow + 8, oh + 8),
          Radius.circular(radius + 4)),
      glowPaint,
    );

    // Main body gradient
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [mainColor, mainColor.withOpacity(0.75)],
      ).createShader(Rect.fromLTWH(ox, oy, ow, oh));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(ox, oy, ow, oh), Radius.circular(radius)),
      bodyPaint,
    );

    // Top shine
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(ox + 4, oy + 2, ow - 8, oh * 0.3),
          const Radius.circular(4)),
      Paint()..color = Colors.white.withOpacity(0.25),
    );

    // ── FluxBlock: lane-signal indicator ────────────────────────────────────
    // Shows which lane the block will jump to next, with a countdown arc
    // so the player always knows where to dodge.
    if (obs.type == ObstacleType.fluxBlock) {
      _drawFluxLaneSignal(canvas, obs, ox, oy, ow, oh, lw);
    }
  }

  /// Draws a compact directional arrow + countdown arc on a fluxBlock
  /// so the player knows which lane it will shift into next.
  void _drawFluxLaneSignal(
      Canvas canvas,
      Obstacle obs,
      double ox,
      double oy,
      double ow,
      double oh,
      double laneWidth,
      ) {
    final bool goingRight = obs.nextLane > obs.lane;
    final double progress = obs.fluxProgress; // 0→1 as jump approaches

    // ── Countdown arc in top-right corner of the block ───────────────────
    const double arcR = 9.0;
    final Offset arcCenter = Offset(ox + ow - arcR - 4, oy + arcR + 4);

    // Background circle
    canvas.drawCircle(
      arcCenter,
      arcR,
      Paint()..color = Colors.black.withOpacity(0.25),
    );

    // Filled sweep (white → yellow as time runs out)
    final arcColor = Color.lerp(
      Colors.white.withOpacity(0.9),
      const Color(0xFFFFD740),
      progress,
    )!;
    canvas.drawArc(
      Rect.fromCircle(center: arcCenter, radius: arcR - 1),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = arcColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // ── Arrow in the center of the block ──────────────────────────────────
    final double cx = ox + ow / 2;
    final double cy = oy + oh / 2;
    const double arrowLen = 12.0;
    const double arrowHead = 5.0;

    // Arrow shaft
    final double x1 = cx + (goingRight ? -arrowLen / 2 : arrowLen / 2);
    final double x2 = cx + (goingRight ? arrowLen / 2 : -arrowLen / 2);

    final arrowPaint = Paint()
      ..color = Colors.white.withOpacity(0.92)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(x1, cy), Offset(x2, cy), arrowPaint);

    // Arrow head
    final path = Path();
    if (goingRight) {
      path.moveTo(x2, cy);
      path.lineTo(x2 - arrowHead, cy - arrowHead * 0.6);
      path.moveTo(x2, cy);
      path.lineTo(x2 - arrowHead, cy + arrowHead * 0.6);
    } else {
      path.moveTo(x2, cy);
      path.lineTo(x2 + arrowHead, cy - arrowHead * 0.6);
      path.moveTo(x2, cy);
      path.lineTo(x2 + arrowHead, cy + arrowHead * 0.6);
    }
    canvas.drawPath(path, arrowPaint);

    // ── Target lane highlight strip (top of screen) ───────────────────────
    // A subtle coloured strip at the top of the target lane warns the player
    // even before the obstacle reaches them.
    if (progress > 0.45) {
      final double targetLaneX = laneWidth * obs.nextLane;
      final highlightOpacity = ((progress - 0.45) / 0.55).clamp(0.0, 0.55);
      final highlightPaint = Paint()
        ..color = const Color(0xFFFFD740).withOpacity(highlightOpacity)
        ..maskFilter =
        const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRect(
        Rect.fromLTWH(targetLaneX + 2, oy - 18, laneWidth - 4, 14),
        highlightPaint,
      );
    }
  }

  // ── Trail ──────────────────────────────────────────────────────────────────

  void _drawTrail(Canvas canvas) {
    if (ctrl.trailPoints.length < 2) return;
    for (int i = 1; i < ctrl.trailPoints.length; i++) {
      final t = i / ctrl.trailPoints.length;
      final paint = Paint()
        ..color = AppTheme.neonCyan.withOpacity(t * 0.5)
        ..strokeWidth = GameConstants.playerW * 0.35 * t
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * t);
      canvas.drawLine(ctrl.trailPoints[i - 1], ctrl.trailPoints[i], paint);
    }
  }

  // ── Player ─────────────────────────────────────────────────────────────────

  void _drawPlayer(Canvas canvas) {
    final cx = ctrl.playerCurrentX;
    final cy = ctrl.playerY + GameConstants.playerH / 2;
    final pw = GameConstants.playerW;
    final ph = GameConstants.playerH;

    // Outer glow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx, cy), width: pw + 20, height: ph + 20),
          const Radius.circular(16)),
      Paint()
        ..color = AppTheme.neonCyan.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    // Inner glow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx, cy), width: pw + 8, height: ph + 8),
          const Radius.circular(12)),
      Paint()
        ..color = AppTheme.neonCyan.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Body
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF80FFFF), Color(0xFF00B8D4)],
      ).createShader(
          Rect.fromCenter(center: Offset(cx, cy), width: pw, height: ph));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: pw, height: ph),
          const Radius.circular(10)),
      bodyPaint,
    );

    // Nose
    final nosePath = Path()
      ..moveTo(cx, cy - ph / 2 - 8)
      ..lineTo(cx - pw * 0.3, cy - ph / 2 + 4)
      ..lineTo(cx + pw * 0.3, cy - ph / 2 + 4)
      ..close();
    canvas.drawPath(
        nosePath, Paint()..color = const Color(0xFF80FFFF));

    // Core dot
    canvas.drawCircle(
      Offset(cx, cy),
      5,
      Paint()..color = Colors.white.withOpacity(0.9),
    );

    // Shine
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(
              cx - pw / 2 + 4, cy - ph / 2 + 4, pw * 0.4, ph * 0.28),
          const Radius.circular(4)),
      Paint()..color = Colors.white.withOpacity(0.4),
    );
  }

  // ── Particles ──────────────────────────────────────────────────────────────

  void _drawParticles(Canvas canvas, Size size) {
    for (final p in ctrl.particles.particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.life.clamp(0, 1))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(p.position, p.size * p.life.clamp(0, 1), paint);
    }
  }

  @override
  bool shouldRepaint(GamePainter old) => true;
}