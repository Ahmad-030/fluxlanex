import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../audio/audio_manager.dart';
import '../utils/prefs_manager.dart';
import 'menu_screen.dart';
import 'game_screen.dart';

class GameOverScreen extends StatefulWidget {
  final int score;
  final int highScore;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.highScore,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  bool _isNewRecord = false;
  final AudioManager _audio = AudioManager();

  @override
  void initState() {
    super.initState();
    _checkRecord();
  }

  Future<void> _checkRecord() async {
    final saved = await PrefsManager.getHighScore();
    if (widget.score >= saved) {
      await PrefsManager.saveHighScore(widget.score);
      if (widget.score > saved) {
        setState(() => _isNewRecord = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F9FF), Color(0xFFDEF0FF), Color(0xFFC8E8FF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lottie crash animation
                  SizedBox(
                    height: 160,
                    child: Lottie.asset(
                      'assets/lottie/crash.json',
                      repeat: false,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.flash_on_rounded,
                        size: 80,
                        color: Color(0xFFFF4D6D),
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms),

                  const SizedBox(height: 8),

                  Text(
                    'GAME OVER',
                    style: GoogleFonts.orbitron(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFFF4D6D),
                      letterSpacing: 3,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 500.ms)
                      .scale(
                          begin: const Offset(0.7, 0.7),
                          delay: 300.ms,
                          duration: 600.ms,
                          curve: Curves.elasticOut),

                  const SizedBox(height: 32),

                  // Score card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: const Color(0xFF00E5FF).withOpacity(0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withOpacity(0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'YOUR SCORE',
                          style: GoogleFonts.orbitron(
                            fontSize: 10,
                            color: const Color(0xFF718096),
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.score}',
                          style: GoogleFonts.orbitron(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF00B8D4),
                          ),
                        ),
                        const Divider(height: 28, color: Color(0xFFE2E8F0)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.emoji_events_rounded,
                                color: Color(0xFFFFB700), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'BEST: ${widget.highScore}',
                              style: GoogleFonts.orbitron(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A202C),
                              ),
                            ),
                          ],
                        ),
                        if (_isNewRecord) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFFB700)]),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '🏆 NEW RECORD!',
                              style: GoogleFonts.orbitron(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scaleXY(begin: 0.97, end: 1.03, duration: 700.ms),
                        ],
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 600.ms)
                      .slideY(
                          begin: 0.2, end: 0, delay: 500.ms, duration: 600.ms, curve: Curves.easeOut),

                  const SizedBox(height: 32),

                  // Buttons
                  _GameOverButton(
                    label: 'PLAY AGAIN',
                    icon: Icons.refresh_rounded,
                    isPrimary: true,
                    onTap: () {
                      _audio.resumeMusic();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) =>
                              GameScreen(highScore: widget.highScore),
                        ),
                      );
                    },
                  ).animate().fadeIn(delay: 800.ms, duration: 400.ms),

                  const SizedBox(height: 14),

                  _GameOverButton(
                    label: 'MAIN MENU',
                    icon: Icons.home_rounded,
                    onTap: () {
                      _audio.resumeMusic();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MenuScreen()),
                      );
                    },
                  ).animate().fadeIn(delay: 950.ms, duration: 400.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameOverButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _GameOverButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)])
              : null,
          color: isPrimary ? null : Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? Colors.transparent : const Color(0xFF00E5FF).withOpacity(0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? const Color(0xFF00E5FF).withOpacity(0.4)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: isPrimary ? Colors.white : const Color(0xFF00B8D4)),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.orbitron(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isPrimary ? Colors.white : const Color(0xFF1A202C),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
