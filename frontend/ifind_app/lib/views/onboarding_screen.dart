import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind_app/views/home_screen.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kPrimary    = Color(0xFF135BEC);
const _kBackground = Color(0xFF101622);
const _kSlate700   = Color(0xFF334155);
const _kSlate800   = Color(0xFF1E293B);

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

        // ── Main scrollable content ──────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // ── Onboarding illustration ────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/onboarding1.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    width: double.infinity,
                    height: cardSize,
                  ),
                ),

                const SizedBox(height: 32),

                // ── Title ──────────────────────────────────────────────────
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

                // ── Subtitle ───────────────────────────────────────────────
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

                // ── Dots ───────────────────────────────────────────────────
                _PageDots(currentPage: currentPage, totalPages: 2),

                const SizedBox(height: 32),

                // ── Next button ────────────────────────────────────────────
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
        // ── Top bar (Skip only — no iFind title per design) ─────────────────
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

        // ── Main scrollable content ──────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // ── Onboarding illustration ────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/onboarding2.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    width: double.infinity,
                    height: cardSize,
                  ),
                ),

                const SizedBox(height: 32),

                // ── Title ──────────────────────────────────────────────────
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

                // ── Subtitle ───────────────────────────────────────────────
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

                // ── Dots ───────────────────────────────────────────────────
                _PageDots(currentPage: currentPage, totalPages: 2),

                const SizedBox(height: 32),

                // ── Get Started button ─────────────────────────────────────
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

                // ── Back button ────────────────────────────────────────────
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
