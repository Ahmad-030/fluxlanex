import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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
          Image.asset(
            'assets/images/splash_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _gradientBg(),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x88F0F4FF), Color(0xCCDEF0FF)],
              ),
            ),
          ),
          // FIX: Use Center so Column doesn't fight for infinite height
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.9),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withOpacity(0.6),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    size: 60,
                    color: Color(0xFF00B8D4),
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

  Widget _gradientBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0F9FF), Color(0xFFDEF0FF), Color(0xFFC8E8FF)],
        ),
      ),
    );
  }
}

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
            // FIX: explicit double arithmetic — no int/double cast error
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