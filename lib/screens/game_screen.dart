import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../audio/audio_manager.dart';
import '../utils/prefs_manager.dart';
import '../game/game_controller.dart';
import '../game/game_painter.dart';
import '../game/game_constants.dart';
import 'game_over_screen.dart';

class GameScreen extends StatefulWidget {
  final int highScore;
  const GameScreen({super.key, required this.highScore});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameController _ctrl;
  late Ticker _ticker;
  final AudioManager _audio = AudioManager();

  // Swipe tracking
  double _swipeStartX = 0;
  double _swipeStartY = 0;
  static const double _swipeThreshold = 30.0;

  // Tap flash feedback
  bool _leftFlash = false;
  bool _rightFlash = false;

  @override
  void initState() {
    super.initState();
    _ctrl = GameController();
    _ticker = createTicker(_ctrl.tick);
    _ctrl.addListener(_onGameStateChange);
  }

  void _onGameStateChange() {
    if (_ctrl.state == GameState.gameOver && mounted) {
      _audio.pauseMusic();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _showGameOver();
      });
    }
    if (mounted) setState(() {});
  }

  void _showGameOver() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => GameOverScreen(
          score: _ctrl.score,
          highScore: _ctrl.highScore,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _startGame(double w, double h) {
    if (_ctrl.state == GameState.idle) {
      _ctrl.setup(w, h, widget.highScore);
      _ctrl.startGame();
      _ctrl.attachTicker(_ticker);
      _audio.resumeMusic();
    }
  }

  void _tapLeft() {
    _ctrl.moveLeft();
    setState(() => _leftFlash = true);
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _leftFlash = false);
    });
  }

  void _tapRight() {
    _ctrl.moveRight();
    setState(() => _rightFlash = true);
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _rightFlash = false);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _ctrl.removeListener(_onGameStateChange);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double w = constraints.maxWidth;
            final double h = constraints.maxHeight;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _startGame(w, h);
            });

            return Stack(
              children: [
                // Background gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF0F9FF), Color(0xFFDEF0FF)],
                    ),
                  ),
                ),

                // FIX: Single GestureDetector covers the full game area.
                // Handles BOTH taps (left/right half) AND swipe gestures correctly.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  // --- SWIPE ---
                  onPanStart: (details) {
                    _swipeStartX = details.globalPosition.dx;
                    _swipeStartY = details.globalPosition.dy;
                  },
                  onPanEnd: (details) {
                    final double dx =
                        details.velocity.pixelsPerSecond.dx;
                    final double dy =
                    details.velocity.pixelsPerSecond.dy.abs();
                    // Only register as horizontal swipe if horizontal velocity
                    // is dominant and exceeds threshold
                    if (dx.abs() > _swipeThreshold && dx.abs() > dy) {
                      if (dx < 0) {
                        _tapLeft();
                      } else {
                        _tapRight();
                      }
                    }
                  },
                  // --- TAP (left/right half) ---
                  onTapUp: (details) {
                    if (_ctrl.state != GameState.playing) return;
                    final double tapX = details.localPosition.dx;
                    if (tapX < w / 2) {
                      _tapLeft();
                    } else {
                      _tapRight();
                    }
                  },
                  child: Stack(
                    children: [
                      // Game canvas
                      CustomPaint(
                        size: Size(w, h),
                        painter: GamePainter(_ctrl),
                      ),

                      // Visual tap feedback overlays
                      Positioned.fill(
                        child: Row(
                          children: [
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                color: _leftFlash
                                    ? const Color(0xFF00E5FF).withOpacity(0.08)
                                    : Colors.transparent,
                              ),
                            ),
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                color: _rightFlash
                                    ? const Color(0xFF00E5FF).withOpacity(0.08)
                                    : Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // HUD (on top, non-intercepting for taps below)
                IgnorePointer(
                  ignoring: true,
                  child: _buildHUD(),
                ),

                // Pause button (needs its own tap — not ignored)
                Positioned(
                  top: 8,
                  left: 16,
                  child: GestureDetector(
                    onTap: () {
                      _ctrl.pauseGame();
                      _audio.pauseMusic();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF00E5FF).withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.pause_rounded,
                          color: Color(0xFF00B8D4), size: 22),
                    ),
                  ),
                ),

                // Pause overlay
                if (_ctrl.state == GameState.paused) _buildPauseOverlay(),

                // Flux mode indicator
                if (_ctrl.fluxMode && _ctrl.state == GameState.playing)
                  _buildFluxModeIndicator(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHUD() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.0)
            ],
          ),
        ),
        child: Row(
          children: [
            // Spacer to account for pause button
            const SizedBox(width: 52),

            const Spacer(),

            // Score (center)
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${_ctrl.score}',
                  style: GoogleFonts.orbitron(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1A202C),
                  ),
                ),
                Text(
                  'SCORE',
                  style: GoogleFonts.orbitron(
                    fontSize: 9,
                    color: const Color(0xFF718096),
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Time (right)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(_ctrl.gameTime),
                  style: GoogleFonts.orbitron(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00B8D4),
                  ),
                ),
                Text(
                  'TIME',
                  style: GoogleFonts.orbitron(
                    fontSize: 9,
                    color: const Color(0xFF718096),
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFluxModeIndicator() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.5),
                blurRadius: 16,
              ),
            ],
          ),
          child: Text(
            '⚡ FLUX MODE',
            style: GoogleFonts.orbitron(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fadeIn(duration: 400.ms)
            .then()
            .fadeOut(delay: 600.ms, duration: 400.ms),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.white.withOpacity(0.88),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PAUSED',
                style: GoogleFonts.orbitron(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF00B8D4),
                  letterSpacing: 4,
                ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
              const SizedBox(height: 40),
              _PauseButton(
                label: 'RESUME',
                icon: Icons.play_arrow_rounded,
                isPrimary: true,
                onTap: () {
                  _ctrl.resumeGame();
                  _audio.resumeMusic();
                },
              ),
              const SizedBox(height: 16),
              _PauseButton(
                label: 'RESTART',
                icon: Icons.refresh_rounded,
                onTap: () {
                  _ctrl.startGame();
                  _audio.resumeMusic();
                },
              ),
              const SizedBox(height: 16),
              _PauseButton(
                label: 'MAIN MENU',
                icon: Icons.home_rounded,
                onTap: () {
                  Navigator.of(context).pop();
                  _audio.resumeMusic();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(double seconds) {
    final int m = (seconds / 60).floor();
    final int s = (seconds % 60).floor();
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _PauseButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _PauseButton({
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
        width: 220,
        height: 52,
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)])
              : null,
          color: isPrimary ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary
                ? Colors.transparent
                : const Color(0xFF00E5FF).withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? const Color(0xFF00E5FF).withOpacity(0.4)
                  : Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 20,
                color: isPrimary ? Colors.white : const Color(0xFF00B8D4)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.orbitron(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isPrimary ? Colors.white : const Color(0xFF1A202C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}