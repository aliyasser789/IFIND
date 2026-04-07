import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind_app/views/home_screen.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kPrimary    = Color(0xFF135BEC);
const _kBackground = Color(0xFF101622);
const _kSlate700   = Color(0xFF334155);
const _kSlate800   = Color(0xFF1E293B);
const _kSlate900   = Color(0xFF0F172A);

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingScreen
// ─────────────────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (i) => setState(() => _currentPage = i),
          children: [
            _Page1(
              size: size,
              onSkip: _navigateToHome,
              onNext: () => _goToPage(1),
              currentPage: _currentPage,
            ),
            _Page2(
              size: size,
              onSkip: _navigateToHome,
              onBack: () => _goToPage(0),
              onGetStarted: _navigateToHome,
              currentPage: _currentPage,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 1 — "Lost it? We'll find it."
// ─────────────────────────────────────────────────────────────────────────────
class _Page1 extends StatelessWidget {
  const _Page1({
    required this.size,
    required this.onSkip,
    required this.onNext,
    required this.currentPage,
  });

  final Size size;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    final cardSize = size.width - 48;

    return Column(
      children: [
        // ── Top bar ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 72),
              Text(
                'iFind',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: onSkip,
                child: Text(
                  'Skip',
                  style: GoogleFonts.manrope(
                    color: _kPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Main scrollable content ──────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // ── Map card ───────────────────────────────────────────
                SizedBox(
                  width: cardSize,
                  height: cardSize,
                  child: _MapCard(size: cardSize),
                ),

                const SizedBox(height: 32),

                // ── Title ──────────────────────────────────────────────
                Text(
                  "Lost it? We'll find it.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 16),

                // ── Subtitle ───────────────────────────────────────────
                Text(
                  "Connect with a community dedicated to returning lost items. Whether it's a key, a pet, or a phone, we're here to help.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF94A3B8),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 32),

                // ── Dots ───────────────────────────────────────────────
                _PageDots(currentPage: currentPage, totalPages: 2),

                const SizedBox(height: 32),

                // ── Next button ────────────────────────────────────────
                _PrimaryButton(
                  onTap: onNext,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Next',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 2 — "Be a Hero."
// ─────────────────────────────────────────────────────────────────────────────
class _Page2 extends StatelessWidget {
  const _Page2({
    required this.size,
    required this.onSkip,
    required this.onBack,
    required this.onGetStarted,
    required this.currentPage,
  });

  final Size size;
  final VoidCallback onSkip;
  final VoidCallback onBack;
  final VoidCallback onGetStarted;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    final cardSize = size.width - 48;

    return Column(
      children: [
        // ── Top bar (Skip only — no iFind title per design) ─────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onSkip,
                child: Text(
                  'Skip',
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF94A3B8),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Main scrollable content ──────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // ── Hero card ──────────────────────────────────────────
                SizedBox(
                  width: cardSize,
                  height: cardSize,
                  child: _HeroCard(size: cardSize),
                ),

                const SizedBox(height: 32),

                // ── Title ──────────────────────────────────────────────
                Text(
                  'Be a Hero.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 16),

                // ── Subtitle ───────────────────────────────────────────
                Text(
                  'Found something? List it easily and help it get home.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF94A3B8),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 32),

                // ── Dots ───────────────────────────────────────────────
                _PageDots(currentPage: currentPage, totalPages: 2),

                const SizedBox(height: 32),

                // ── Get Started button ─────────────────────────────────
                _PrimaryButton(
                  onTap: onGetStarted,
                  child: Text(
                    'Get Started',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Back button ────────────────────────────────────────
                _OutlineButton(
                  onTap: onBack,
                  label: 'Back',
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map Card — Page 1 illustration (map simulation with grid lines)
// ─────────────────────────────────────────────────────────────────────────────
class _MapCard extends StatelessWidget {
  const _MapCard({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.15),
            blurRadius: 40,
            spreadRadius: -8,
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Grid lines (map simulation)
          Positioned.fill(child: CustomPaint(painter: _MapGridPainter())),

          // Road-like horizontal lines
          ...List.generate(6, (i) {
            return Positioned(
              top: size * (0.15 + i * 0.13),
              left: 0,
              right: 0,
              child: Container(
                height: i.isEven ? 2 : 1,
                color: i.isEven
                    ? const Color(0xFF2A3F6F).withValues(alpha: 0.8)
                    : const Color(0xFF1E2E50).withValues(alpha: 0.5),
              ),
            );
          }),

          // Road-like vertical lines
          ...List.generate(5, (i) {
            return Positioned(
              left: size * (0.15 + i * 0.18),
              top: 0,
              bottom: 0,
              child: Container(
                width: i.isEven ? 2 : 1,
                color: i.isEven
                    ? const Color(0xFF2A3F6F).withValues(alpha: 0.8)
                    : const Color(0xFF1E2E50).withValues(alpha: 0.5),
              ),
            );
          }),

          // City block fills
          Positioned(
            left: size * 0.33,
            top: size * 0.28,
            child: Container(
              width: size * 0.28,
              height: size * 0.24,
              decoration: BoxDecoration(
                color: const Color(0xFF223159).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            left: size * 0.15,
            top: size * 0.55,
            child: Container(
              width: size * 0.20,
              height: size * 0.18,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3060).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            left: size * 0.62,
            top: size * 0.54,
            child: Container(
              width: size * 0.22,
              height: size * 0.20,
              decoration: BoxDecoration(
                color: const Color(0xFF223159).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Center location pin
          Positioned(
            left: size * 0.5 - 16,
            top: size * 0.4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimary.withValues(alpha: 0.5),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.location_on, color: Colors.white, size: 18),
                ),
                Container(
                  width: 2,
                  height: 8,
                  color: _kPrimary,
                ),
              ],
            ),
          ),

          // "RECENTLY LOST" chip — top left
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _kSlate900.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kPrimary.withValues(alpha: 0.4), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, color: _kPrimary, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'RECENTLY LOST',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Card — Page 2 illustration
// ─────────────────────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFD4A574).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.12),
            blurRadius: 40,
            spreadRadius: -8,
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Warm background gradient (matches illustration tone)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF5C896).withValues(alpha: 0.25),
                    const Color(0xFFE8A86C).withValues(alpha: 0.15),
                  ],
                ),
              ),
            ),
          ),

          // Locker/cabinet shape (center-right)
          Positioned(
            right: size * 0.20,
            top: size * 0.15,
            child: Container(
              width: size * 0.30,
              height: size * 0.65,
              decoration: BoxDecoration(
                color: const Color(0xFF4A5568),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: size * 0.22,
                    height: size * 0.28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D3748),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF718096), width: 1),
                    ),
                    child: const Center(
                      child: Icon(Icons.lock_outline, color: Color(0xFF718096), size: 20),
                    ),
                  ),
                  Container(
                    width: size * 0.22,
                    height: size * 0.25,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D3748),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF718096), width: 1),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Plant decoration (left side)
          Positioned(
            left: size * 0.04,
            bottom: size * 0.05,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: size * 0.12,
                  height: size * 0.25,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A7C59).withValues(alpha: 0.8),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                ),
                Container(
                  width: size * 0.08,
                  height: size * 0.12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),

          // Person silhouette (center-left)
          Positioned(
            left: size * 0.28,
            bottom: size * 0.05,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Head
                Container(
                  width: size * 0.10,
                  height: size * 0.10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4956A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 2),
                // Body (orange shirt)
                Container(
                  width: size * 0.14,
                  height: size * 0.22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8873A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, right: 2),
                      child: Icon(Icons.vpn_key, color: Colors.white.withValues(alpha: 0.9), size: 14),
                    ),
                  ),
                ),
                // Legs (dark trousers)
                Container(
                  width: size * 0.12,
                  height: size * 0.16,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2D3748),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Blue badge — bottom right
          Positioned(
            bottom: size * 0.10,
            right: size * 0.10,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _kPrimary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withValues(alpha: 0.5),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.volunteer_activism, color: Colors.white, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page Dots
// ─────────────────────────────────────────────────────────────────────────────
class _PageDots extends StatelessWidget {
  const _PageDots({required this.currentPage, required this.totalPages});
  final int currentPage;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (i) {
        final isActive = i == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? _kPrimary : _kSlate700,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Primary Button (blue, full-width)
// ─────────────────────────────────────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _kPrimary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Outline Button (white border, full-width) — used for "Back"
// ─────────────────────────────────────────────────────────────────────────────
class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.onTap, required this.label});
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kSlate800, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map Grid Painter — subtle dot grid overlay
// ─────────────────────────────────────────────────────────────────────────────
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2A3F6F).withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_MapGridPainter old) => false;
}
