import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F9FF), Color(0xFFDEF0FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF00E5FF).withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF00B8D4), size: 18),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'ABOUT',
                      style: GoogleFonts.orbitron(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A202C),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Logo & Lottie
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

                      const SizedBox(height: 8),

                      Text(
                        'FluxLaneX',
                        style: GoogleFonts.orbitron(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF00B8D4),
                          letterSpacing: 1.5,
                        ),
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 4),
                      Text(
                        'REFLEX ARCADE',
                        style: GoogleFonts.orbitron(
                          fontSize: 11,
                          color: const Color(0xFF718096),
                          letterSpacing: 3,
                        ),
                      ).animate().fadeIn(delay: 300.ms),

                      const SizedBox(height: 28),

                      // About card
                      _AboutCard(
                        delay: 200,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CardRow(
                              icon: Icons.videogame_asset_rounded,
                              label: 'ABOUT THE GAME',
                              isHeader: true,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'FluxLaneX is a high-speed reflex arcade game where you control a glowing ship through dynamically shifting lanes. Dodge obstacles, survive Flux Mode, and beat your high score!',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF4A5568),
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      _AboutCard(
                        delay: 300,
                        child: Column(
                          children: [
                            _CardRow(
                              icon: Icons.code_rounded,
                              label: 'DEVELOPER',
                              isHeader: true,
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                                icon: Icons.person_rounded, label: 'Bonepau'),
                            const SizedBox(height: 8),
                            _InfoRow(
                                icon: Icons.email_rounded,
                                label: 'thanhtanfis37@gmail.com'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      _AboutCard(
                        delay: 400,
                        child: Column(
                          children: [
                            _CardRow(
                              icon: Icons.sports_esports_rounded,
                              label: 'HOW TO PLAY',
                              isHeader: true,
                            ),
                            const SizedBox(height: 12),
                            _HowToRow(
                                icon: Icons.touch_app_rounded,
                                text: 'Tap left half → Move left'),
                            _HowToRow(
                                icon: Icons.touch_app_rounded,
                                text: 'Tap right half → Move right'),
                            _HowToRow(
                                icon: Icons.swipe_rounded,
                                text: 'Swipe left/right → Switch lane'),
                            _HowToRow(
                                icon: Icons.bolt_rounded,
                                text: 'Survive to unlock Flux Mode!'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      _AboutCard(
                        delay: 500,
                        child: Column(
                          children: [
                            _CardRow(
                              icon: Icons.star_rounded,
                              label: 'OBSTACLE TYPES',
                              isHeader: true,
                            ),
                            const SizedBox(height: 12),
                            _ObstacleRow(
                              color: const Color(0xFFFF4D6D),
                              name: 'Static Block',
                              desc: 'Simple lane blockers',
                            ),
                            _ObstacleRow(
                              color: const Color(0xFFFF9F1C),
                              name: 'Flux Block ⭐',
                              desc: 'Shifts between lanes — stay sharp!',
                            ),
                            _ObstacleRow(
                              color: const Color(0xFFBD93F9),
                              name: 'Pulse Bar',
                              desc: 'Expands and contracts — time it right',
                            ),
                            _ObstacleRow(
                              color: const Color(0xFFFF2D55),
                              name: 'Flash Wall',
                              desc: 'Appears suddenly — react instantly',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final Widget child;
  final int delay;
  const _AboutCard({required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideY(
            begin: 0.1,
            end: 0,
            delay: Duration(milliseconds: delay),
            duration: 400.ms);
  }
}

class _CardRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isHeader;
  const _CardRow({required this.icon, required this.label, this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF00B8D4)),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.orbitron(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF00B8D4),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF718096)),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF1A202C),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _HowToRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HowToRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF00B8D4)),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF4A5568),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObstacleRow extends StatelessWidget {
  final Color color;
  final String name;
  final String desc;
  const _ObstacleRow(
      {required this.color, required this.name, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A202C)),
              ),
              Text(
                desc,
                style: GoogleFonts.inter(
                    fontSize: 11, color: const Color(0xFF718096)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
