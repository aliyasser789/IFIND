import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/storage_service.dart';
import 'auth_screen.dart';
import 'id_verification_screen.dart';
import 'main_shell.dart';

// ─── Design tokens ──────────────────────────────────────────────────────────
const _kPrimary      = Color(0xFF135BEC);
const _kAccentPurple = Color(0xFF8B5CF6);
const _kBackground   = Color(0xFF0A1228);   // darkest navy (screenshot top)
const _kBgBottom     = Color(0xFF190D3A);   // deep purple (screenshot bottom)
const _kSlate900     = Color(0xFF0F172A);
const _kSlate300     = Color(0xFFCBD5E1);
const _kSlate400     = Color(0xFF94A3B8);
const _kSlate500     = Color(0xFF64748B);

// ─── Spacing scale ───────────────────────────────────────────────────────────
const double _sp8  = 8;
const double _sp16 = 16;
const double _sp24 = 24;
const double _sp32 = 32;
const double _sp48 = 48;
const double _sp64 = 64;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Progress bar fills over 5 seconds then navigates
  late final AnimationController _progressController;
  late final Animation<double>   _progressAnim;

  // Hero entrance: fade + scale
  late final AnimationController _heroController;
  late final Animation<double>   _heroOpacity;
  late final Animation<double>   _heroScale;

  // Pulsing glow on the logo card
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _progressAnim = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );

    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _heroOpacity = CurvedAnimation(
      parent: _heroController,
      curve: const Interval(0.05, 1.0, curve: Curves.easeOut),
    );
    _heroScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _heroController.forward();
    _progressController.forward();
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _openNextScreen();
    });
  }

  Future<void> _openNextScreen() async {
    if (!mounted) return;
    final token = await StorageService().getToken();
    if (!mounted) return;

    if (token == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      return;
    }

    final idVerified = await StorageService().getIdVerified();
    if (!mounted) return;

    if (idVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
      final email = await StorageService().getUserEmail() ?? '';
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => IdVerificationScreen(email: email),
        ),
        (_) => false,
      );
    }
  }

  @override
  void dispose() {
    _heroController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size    = MediaQuery.of(context).size;
    final compact = size.height < 730;

    return Scaffold(
      backgroundColor: _kBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: rich background gradient ─────────────────────────
          const _SplashBackdrop(),

          // ── Layer 2: ambient blobs ─────────────────────────────────────
          _AmbientBlob(
            top:      size.height * 0.20,
            left:     -80,
            diameter: 280,
            color:    _kPrimary,
            opacity:  0.13,
          ),
          _AmbientBlob(
            bottom:   size.height * 0.20,
            right:    -80,
            diameter: 280,
            color:    _kAccentPurple,
            opacity:  0.15,
          ),

          // ── Layer 3: main content ──────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: _sp32),
              child: Column(
                children: [
                  SizedBox(height: compact ? _sp48 : _sp64 + _sp16),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeTransition(
                          opacity: _heroOpacity,
                          child: ScaleTransition(
                            scale: _heroScale,
                            child: _LogoCard(
                              compact:         compact,
                              pulseController: _pulseController,
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? _sp24 : _sp32),
                        FadeTransition(
                          opacity: _heroOpacity,
                          child: _buildTitle(compact: compact),
                        ),
                      ],
                    ),
                  ),

                  _buildBottomSection(compact: compact),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle({required bool compact}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.manrope(
              fontSize:      compact ? 56.0 : 64.0,
              fontWeight:    FontWeight.w800,
              letterSpacing: -1.5,
              height:        1.0,
            ),
            children: const [
              TextSpan(text: 'i',    style: TextStyle(color: Colors.white)),
              TextSpan(text: 'Find', style: TextStyle(color: _kPrimary)),
            ],
          ),
        ),
        const SizedBox(height: _sp8 + 2),
        Container(
          width:  56,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [_kPrimary, _kAccentPurple],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection({required bool compact}) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? _sp32 : _sp48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Find what's lost,",
            style: GoogleFonts.manrope(
              color:         _kSlate300,
              fontSize:      compact ? 18.0 : 20.0,
              fontWeight:    FontWeight.w500,
              height:        1.4,
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            "return what's found",
            style: GoogleFonts.manrope(
              color:         _kSlate400,
              fontSize:      compact ? 18.0 : 20.0,
              fontWeight:    FontWeight.w400,
              height:        1.4,
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: compact ? _sp24 : _sp32),

          // Animated progress bar
          SizedBox(
            width:  224,
            height: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Container(
                      width:  constraints.maxWidth,
                      height: constraints.maxHeight,
                      color:  Colors.white.withValues(alpha: 0.10),
                    ),
                    AnimatedBuilder(
                      animation: _progressAnim,
                      builder: (context, _) => Container(
                        width:  constraints.maxWidth *
                                math.max(0.0, _progressAnim.value),
                        height: constraints.maxHeight,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kPrimary, _kAccentPurple],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:      _kPrimary.withValues(alpha: 0.65),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: compact ? _sp24 : _sp32),

          Text(
            'PREMIUM LOST & FOUND',
            style: GoogleFonts.manrope(
              color:         _kSlate500,
              fontSize:      11,
              fontWeight:    FontWeight.w600,
              letterSpacing: 4.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Logo Card ───────────────────────────────────────────────────────────────

class _LogoCard extends StatelessWidget {
  const _LogoCard({
    required this.compact,
    required this.pulseController,
  });

  final bool              compact;
  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    final double cardSize   = compact ? 116.0 : 128.0;
    const double cardRadius = 32.0;
    final double iconSize   = cardSize * 0.56;

    return Stack(
      alignment: Alignment.center,
      children: [
        // ── Pulsing outer glow ─────────────────────────────────────────
        AnimatedBuilder(
          animation: pulseController,
          builder: (context, _) {
            final t = pulseController.value; // 0 → 1 → 0 (repeat reverse)
            final glowOpacity = 0.25 + 0.20 * t;
            final glowSpread  = 6.0  + 6.0  * t;
            return Container(
              width:  cardSize + glowSpread * 2,
              height: cardSize + glowSpread * 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cardRadius + 8),
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end:   Alignment.topRight,
                  colors: [
                    _kPrimary.withValues(alpha: glowOpacity),
                    _kAccentPurple.withValues(alpha: glowOpacity),
                  ],
                ),
              ),
            );
          },
        ),

        // ── Blurred glow layer (static depth) ─────────────────────────
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width:  cardSize + 16,
            height: cardSize + 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cardRadius + 4),
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end:   Alignment.topRight,
                colors: [
                  _kPrimary.withValues(alpha: 0.45),
                  _kAccentPurple.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
        ),

        // ── Card body ─────────────────────────────────────────────────
        Container(
          width:  cardSize,
          height: cardSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cardRadius),
            color:  _kSlate900,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withValues(alpha: 0.55),
                blurRadius: 40,
                offset:     const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cardRadius),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Internal gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin:  Alignment.topLeft,
                        end:    Alignment.bottomRight,
                        colors: [
                          _kPrimary.withValues(alpha: 0.22),
                          Colors.transparent,
                          _kAccentPurple.withValues(alpha: 0.22),
                        ],
                        stops: const [0.0, 0.50, 1.0],
                      ),
                    ),
                  ),
                ),

                // Background blurred ring
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Icon(
                    Icons.radio_button_checked,
                    size:  iconSize * 1.25,
                    color: _kPrimary.withValues(alpha: 0.35),
                  ),
                ),

                // Main location icon with glow
                ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) => const RadialGradient(
                    center: Alignment(0, -0.3),
                    radius: 0.65,
                    colors: [Color(0xFFFFFFFF), Color(0xFFD0DEFF)],
                  ).createShader(bounds),
                  child: Icon(
                    Icons.location_on,
                    size:  iconSize,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color:      Colors.white.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset:     Offset.zero,
                      ),
                      Shadow(
                        color:      _kPrimary.withValues(alpha: 0.30),
                        blurRadius: 28,
                        offset:     Offset.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Background Backdrop ──────────────────────────────────────────────────────
// Linear base (navy → deep purple) + corner radial color blobs

class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        // Base: navy top → deep purple bottom (matches screenshot)
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin:  Alignment.topCenter,
              end:    Alignment.bottomCenter,
              colors: [_kBackground, _kBgBottom],
              stops:  [0.0, 1.0],
            ),
          ),
        ),

        // Top-left blue radial
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-1.0, -1.0),
              radius: 1.40,
              colors: [Color(0x55135BEC), Color(0x00135BEC)],
            ),
          ),
        ),

        // Bottom-right purple radial
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(1.0, 1.0),
              radius: 1.40,
              colors: [Color(0x558B5CF6), Color(0x008B5CF6)],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Ambient Blob ────────────────────────────────────────────────────────────

class _AmbientBlob extends StatelessWidget {
  const _AmbientBlob({
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.diameter,
    required this.color,
    required this.opacity,
  });

  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final double  diameter;
  final Color   color;
  final double  opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top:    top,
      right:  right,
      bottom: bottom,
      left:   left,
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
          child: Container(
            width:  diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: opacity),
            ),
          ),
        ),
      ),
    );
  }
}
