import 'dart:math';
import 'package:flutter/material.dart';

class Particle {
  Offset position;
  Offset velocity;
  double life; // 0..1
  double size;
  Color color;

  Particle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.size,
    required this.color,
  });

  void update(double dt) {
    position = Offset(
      position.dx + velocity.dx * dt,
      position.dy + velocity.dy * dt,
    );
    velocity = Offset(velocity.dx * 0.96, velocity.dy * 0.96 + 200 * dt);
    life -= dt * 1.6;
  }

  bool get isDead => life <= 0;
}

class ParticleSystem {
  final List<Particle> particles = [];
  final Random _rng = Random();

  void burst(Offset position, {int count = 28}) {
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 120 + _rng.nextDouble() * 320;
      final colors = [
        const Color(0xFF00E5FF),
        const Color(0xFFFF4D6D),
        const Color(0xFFFFFFFF),
        const Color(0xFFFFB3C1),
        const Color(0xFF00B8D4),
      ];
      particles.add(Particle(
        position: position,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        life: 0.6 + _rng.nextDouble() * 0.5,
        size: 3 + _rng.nextDouble() * 6,
        color: colors[_rng.nextInt(colors.length)],
      ));
    }
  }

  void update(double dt) {
    particles.removeWhere((p) => p.isDead);
    for (final p in particles) {
      p.update(dt);
    }
  }

  bool get hasParticles => particles.isNotEmpty;
}

class ParticlePainter extends CustomPainter {
  final ParticleSystem system;
  ParticlePainter(this.system);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in system.particles) {
      final paint = Paint()
        ..color = p.color.withOpacity((p.life).clamp(0, 1))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(p.position, p.size * p.life, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter old) => true;
}
