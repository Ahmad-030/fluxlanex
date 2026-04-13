import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../audio/audio_manager.dart';
import 'menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final AudioManager _audio = AudioManager();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _audio.init();
    await Future.delayed(const Duration(milliseconds: 300));
    await _audio.playMusic();
    await Future.delayed(const Duration(milliseconds: 2400));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MenuScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image ──────────────────────────────────────────────
          // Uses colorBlendMode trick: if image fails to load the gradient
          // fallback is shown instead. The key fix here is making sure
          // pubspec.yaml has assets/images/splash_bg.png declared.
          _buildBackground(),

          // ── Semi-transparent overlay (FIXED: valid hex colors only) ───────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x88F0F4FF), // 53% white-blue
                  Color(0xCCDEF0FF), // 80% light blue
                ],
              ),
            ),
          ),

          // ── Charging Lottie (bottom-left corner) ─────────────────────────


          // ── Main content ──────────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.9),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child:  Positioned(
                    top: 48,
                    right: 16,
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: Lottie.asset(
                        'assets/lottie/Charging.json',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(
                  begin: const Offset(0.6, 0.6),
                  duration: 700.ms,
                  curve: Curves.elasticOut,
                ),
                const SizedBox(height: 28),
                Text(
                  'FluxLaneX',
                  style: GoogleFonts.orbitron(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF00B8D4),
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: const Color(0xFF00E5FF).withOpacity(0.8),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 700.ms)
                    .slideY(
                  begin: 0.3,
                  end: 0.0,
                  delay: 400.ms,
                  duration: 700.ms,
                  curve: Curves.easeOut,
                ),
                const SizedBox(height: 10),
                Text(
                  'REFLEX ARCADE',
                  style: GoogleFonts.orbitron(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF718096),
                    letterSpacing: 5,
                  ),
                ).animate().fadeIn(delay: 700.ms, duration: 600.ms),
                const SizedBox(height: 52),
                const _LoadingDots()
                    .animate()
                    .fadeIn(delay: 1000.ms, duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tries to load splash_bg.png; falls back to gradient if asset is missing.
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0F9FF), Color(0xFFDEF0FF), Color(0xFFC8E8FF)],
        ),
      ),
      child: Image.asset(
        'assets/images/splash_bg.png',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        // errorBuilder silently falls through to the gradient container behind
        errorBuilder: (_, __, ___) => const SizedBox.expand(),
      ),
    );
  }
}

// ── Loading dots ───────────────────────────────────────────────────────────────

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final double phase = (_ctrl.value - i * 0.15).clamp(0.0, 1.0);
            final double brightness =
            phase < 0.5 ? phase * 2.0 : (1.0 - phase) * 2.0;
            final double opacity = (0.3 + 0.7 * brightness).clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E5FF).withOpacity(opacity),
              ),
            );
          }),
        );
      },
    );
  }
}