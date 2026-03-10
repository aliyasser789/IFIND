import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/storage_service.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

// ─── Design tokens (exact match to HTML config) ────────────────────────────
const _kPrimary       = Color(0xFF135BEC);
const _kAccentPurple  = Color(0xFF8B5CF6);
const _kBackground    = Color(0xFF101622);
const _kSlate900      = Color(0xFF0F172A);
const _kSlate300      = Color(0xFFCBD5E1);
const _kSlate400      = Color(0xFF94A3B8);
const _kSlate500      = Color(0xFF64748B);

// ─── Spacing scale: 8 · 16 · 24 · 32 · 48 · 64 ────────────────────────────
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
  late final AnimationController _progressController;
  late final Animation<double>   _progressAnim;
  late final AnimationController _heroController;
  late final Animation<double>   _heroOpacity;
  late final Animation<double>   _heroScale;

  @override
  void initState() {
    super.initState();

    // 7-second loading bar matches the HTML's implied loading duration
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    );
    _progressAnim = CurvedAnimation(
      parent: _progressController,
      curve: Curves.linear,
    );

    // Hero entrance: fade-in + slight scale-up
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _heroOpacity = CurvedAnimation(
      parent: _heroController,
      curve: const Interval(0.08, 1.0, curve: Curves.easeOut),
    );
    _heroScale = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic),
    );

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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            token != null ? const HomeScreen() : const AuthScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _heroController.dispose();
    _progressController.dispose();
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
          // ── Layer 1: mesh background ───────────────────────────────────
          const _SplashBackdrop(),

          // ── Layer 2: ambient mid-screen blobs (HTML positions) ─────────
          // top-1/4, -left-20 → blur-[100px], bg-primary/10
          _AmbientBlob(
            top:      size.height * 0.25,
            left:     -80,
            diameter: 256,
            color:    _kPrimary,
            opacity:  0.10,
          ),
          // bottom-1/4, -right-20 → blur-[100px], bg-accent-purple/10
          _AmbientBlob(
            bottom:   size.height * 0.25,
            right:    -80,
            diameter: 256,
            color:    _kAccentPurple,
            opacity:  0.10,
          ),

          // ── Layer 3: main content ──────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: _sp32),
              child: Column(
                children: [
                  // Top spacer (h-20 = 80px in HTML)
                  SizedBox(height: compact ? _sp48 : _sp64 + _sp16),

                  // Center: logo card + title
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeTransition(
                          opacity: _heroOpacity,
                          child: ScaleTransition(
                            scale: _heroScale,
                            child: _LogoCard(compact: compact),
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

                  // Bottom: tagline + progress bar + label (pb-12 = 48px)
                  _buildBottomSection(compact: compact),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Title: "iFind" + gradient underline ─────────────────────────────────
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
              TextSpan(text: 'i',     style: TextStyle(color: Colors.white)),
              TextSpan(text: 'Find',  style: TextStyle(color: _kPrimary)),
            ],
          ),
        ),
        const SizedBox(height: _sp8 + 2),
        // mt-1 h-1 w-14 → ~4px tall, 56px wide gradient bar
        Container(
          width: 56,
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

  // ── Bottom section ───────────────────────────────────────────────────────
  Widget _buildBottomSection({required bool compact}) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? _sp32 : _sp48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tagline line 1 — slate-300, font-medium
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
          // Tagline line 2 — slate-400, font-normal
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

          // w-56 h-[3px] progress bar with animated fill
          SizedBox(
            width:  224, // w-56 = 14rem = 224px
            height: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    // Track: bg-white/10 — explicit size so it always fills
                    Container(
                      width:  constraints.maxWidth,
                      height: constraints.maxHeight,
                      color:  Colors.white.withValues(alpha: 0.10),
                    ),
                    // Animated fill: explicit width + height from LayoutBuilder
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
                              color:      _kPrimary.withValues(alpha: 0.60),
                              blurRadius: 8,
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

          // "PREMIUM LOST & FOUND" — tracking-[0.25em] slate-500
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
// Replicates HTML structure:
//   <outer glow: gradient-to-tr from-primary to-accent-purple, blur, opacity-40>
//   <card: slate-900, rounded-[2rem], border-white/10>
//     <internal gradient overlay>
//     <location_on icon: white, drop-shadow glow>
//     <radio_button_checked: primary/40, scale-1.25, blur-sm>

class _LogoCard extends StatelessWidget {
  const _LogoCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    // w-32 h-32 = 128px; rounded-[2rem] = 32px
    final double cardSize   = compact ? 116.0 : 128.0;
    const double cardRadius = 32.0;
    final double iconSize   = cardSize * 0.56; // ≈ 72px equivalent

    return Stack(
      alignment: Alignment.center,
      children: [
        // ── Outer glow: blurred gradient rect (HTML: -inset-1.5 blur opacity-40)
        // We use ImageFiltered to apply a real Gaussian blur to a gradient container
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width:  cardSize + 16,
            height: cardSize + 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cardRadius + 4),
              gradient: LinearGradient(
                // gradient-to-tr = bottom-left → top-right
                begin: Alignment.bottomLeft,
                end:   Alignment.topRight,
                colors: [
                  _kPrimary.withValues(alpha: 0.40),
                  _kAccentPurple.withValues(alpha: 0.40),
                ],
              ),
            ),
          ),
        ),

        // ── Main card: slate-900, rounded-[2rem], border white/10 ──────
        Container(
          width:  cardSize,
          height: cardSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cardRadius),
            color:  _kSlate900,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withValues(alpha: 0.50),
                blurRadius: 32,
                offset:     const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cardRadius),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Internal gradient: from-primary/20 via-transparent to-accent-purple/20
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin:  Alignment.topLeft,
                        end:    Alignment.bottomRight,
                        colors: [
                          _kPrimary.withValues(alpha: 0.20),
                          Colors.transparent,
                          _kAccentPurple.withValues(alpha: 0.20),
                        ],
                        stops: const [0.0, 0.50, 1.0],
                      ),
                    ),
                  ),
                ),

                // Secondary icon: radio_button_checked — primary/40, scale-1.25, blur-sm
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                  child: Icon(
                    Icons.radio_button_checked,
                    size:  iconSize * 1.25,
                    color: _kPrimary.withValues(alpha: 0.40),
                  ),
                ),

                // Primary icon: location_on — white, drop-shadow glow
                ShaderMask(
                  blendMode:   BlendMode.srcATop,
                  shaderCallback: (bounds) => const RadialGradient(
                    center: Alignment(0, -0.3),
                    radius: 0.65,
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFD0DEFF),
                    ],
                  ).createShader(bounds),
                  child: Icon(
                    Icons.location_on,
                    size:  iconSize,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color:       Colors.white.withValues(alpha: 0.30),
                        blurRadius:  15,
                        offset:      Offset.zero,
                      ),
                      Shadow(
                        color:       _kPrimary.withValues(alpha: 0.20),
                        blurRadius:  24,
                        offset:      Offset.zero,
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

// ─── Background Backdrop ─────────────────────────────────────────────────────
// HTML: radial at 0%/0% (primary 0.4) + radial at 100%/100% (purple 0.4)
//       over solid #101622 base

class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        // Base dark navy
        ColoredBox(color: _kBackground),

        // Top-left radial: rgba(19, 91, 236, 0.4) circle at 0% 0%
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-1.0, -1.0),
              radius: 1.45,
              colors: [
                Color(0x66135BEC),
                Color(0x00135BEC),
              ],
            ),
          ),
        ),

        // Bottom-right radial: rgba(139, 92, 246, 0.4) circle at 100% 100%
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(1.0, 1.0),
              radius: 1.45,
              colors: [
                Color(0x668B5CF6),
                Color(0x008B5CF6),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Ambient Blob ────────────────────────────────────────────────────────────
// HTML: w-64 h-64 rounded-full blur-[100px] bg-primary/10 or bg-accent-purple/10
// Positioned at top-1/4 / bottom-1/4 on left/right edges

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
          // blur-[100px] ≈ sigmaX/Y of ~50
          imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
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
