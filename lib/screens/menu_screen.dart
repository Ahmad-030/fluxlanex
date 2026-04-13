import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../audio/audio_manager.dart';
import '../utils/prefs_manager.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import 'privacy_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final AudioManager _audio = AudioManager();
  int _highScore = 0;
  bool _musicOn = true;

  late AnimationController _pulseCtrl;

  // Double-back-to-exit
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // ← lifecycle observer
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _loadData();
  }

  // ── App lifecycle: stop music when app goes to background / is closed ──────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _audio.pauseMusic();
        break;
      case AppLifecycleState.resumed:
        if (_musicOn) _audio.resumeMusic();
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _loadData() async {
    final hs = await PrefsManager.getHighScore();
    final m = await PrefsManager.getMusicEnabled();
    if (mounted) {
      setState(() {
        _highScore = hs;
        _musicOn = m;
      });
    }
    if (_musicOn && !_audio.isPlaying) await _audio.playMusic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleMusic() async {
    await _audio.toggleMusic();
    setState(() => _musicOn = _audio.isMusicEnabled);
  }

  // ── Double-back-to-exit logic ─────────────────────────────────────────────
  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Press back again to exit',
            style: GoogleFonts.orbitron(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF00B8D4),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return false; // don't exit yet
    }
    // Second press within 2 s → exit app
    await _audio.stopMusic();
    SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background image (FIXED: gradient container behind image) ────
            _buildBackground(),

            // ── Overlay (FIXED: valid 8-digit hex only) ───────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xAADCEEFF), // ~67% tint
                    Color(0xCCDEF0FF), // ~80% tint
                  ],
                ),
              ),
            ),

            // ── Charging Lottie (top-right corner) ───────────────────────


            // ── Main content ──────────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildTitle(),
                  const SizedBox(height: 12),
                  _buildHighScore(),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        _MenuButton(
                          label: 'PLAY',
                          icon: Icons.play_arrow_rounded,
                          isPrimary: true,
                          delay: 200,
                          onTap: () =>
                              _navigateTo(GameScreen(highScore: _highScore)),
                        ),
                        const SizedBox(height: 14),
                        _MenuButton(
                          label: 'SETTINGS',
                          icon: Icons.settings_rounded,
                          delay: 300,
                          onTap: () =>
                              _navigateTo(const SettingsScreen()),
                        ),
                        const SizedBox(height: 14),
                        _MenuButton(
                          label: 'ABOUT',
                          icon: Icons.info_outline_rounded,
                          delay: 400,
                          onTap: () => _navigateTo(const AboutScreen()),
                        ),
                        const SizedBox(height: 14),
                        _MenuButton(
                          label: 'PRIVACY POLICY',
                          icon: Icons.shield_outlined,
                          delay: 500,
                          onTap: () =>
                              _navigateTo(const PrivacyScreen()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildMusicToggle(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
        .then((_) => _loadData());
  }

  /// Gradient container sits behind the image so if the PNG is missing
  /// the gradient still shows (no black screen).
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
        'assets/images/menu_bg.png',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const SizedBox.expand(),
      ),
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final glow = 0.4 + 0.3 * _pulseCtrl.value;
        return Column(
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
            const SizedBox(height: 12),
            Text(
              'FluxLaneX',
              style: GoogleFonts.orbitron(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF00B8D4),
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    color: const Color(0xFF00E5FF).withOpacity(glow + 0.2),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'REFLEX ARCADE',
              style: GoogleFonts.orbitron(
                fontSize: 11,
                color: const Color(0xFF718096),
                letterSpacing: 5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    )
        .animate()
        .fadeIn(duration: 700.ms)
        .slideY(
        begin: -0.3,
        end: 0,
        duration: 700.ms,
        curve: Curves.easeOut);
  }

  Widget _buildHighScore() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 60),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF00E5FF).withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.12),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded,
              color: Color(0xFFFFB700), size: 18),
          const SizedBox(width: 8),
          Text(
            'BEST: $_highScore',
            style: GoogleFonts.orbitron(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A202C),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 500.ms);
  }

  Widget _buildMusicToggle() {
    return GestureDetector(
      onTap: _toggleMusic,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _musicOn
                ? const Color(0xFF00E5FF).withOpacity(0.5)
                : Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _musicOn ? Icons.music_note_rounded : Icons.music_off_rounded,
              color: _musicOn
                  ? const Color(0xFF00B8D4)
                  : const Color(0xFFADB5BD),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _musicOn ? 'Music: ON' : 'Music: OFF',
              style: GoogleFonts.orbitron(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _musicOn
                    ? const Color(0xFF00B8D4)
                    : const Color(0xFFADB5BD),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 400.ms);
  }
}

// ── Menu button ────────────────────────────────────────────────────────────────

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final int delay;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)],
          )
              : null,
          color: isPrimary ? null : Colors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary
                ? Colors.transparent
                : const Color(0xFF00E5FF).withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? const Color(0xFF00E5FF).withOpacity(0.4)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isPrimary ? 20 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 22,
                color:
                isPrimary ? Colors.white : const Color(0xFF00B8D4)),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.orbitron(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isPrimary
                    ? Colors.white
                    : const Color(0xFF1A202C),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
        delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideX(
        begin: -0.08,
        end: 0,
        delay: Duration(milliseconds: delay),
        duration: 400.ms,
        curve: Curves.easeOut);
  }
}