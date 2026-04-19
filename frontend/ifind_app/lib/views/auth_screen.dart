import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'forgot_password_screen.dart';
import 'id_verification_screen.dart';
import 'main_shell.dart';
import 'register_screen.dart';

// ── Design tokens (shared palette from splash_screen.dart) ──────────────────
const _kPrimary      = Color(0xFF135BEC);
const _kAccentBlue   = Color(0xFF00D2FF);
const _kAccentPurple = Color(0xFF8B5CF6);
const _kBackground   = Color(0xFF101622);
const _kSlate900     = Color(0xFF0F172A);
const _kSlate300     = Color(0xFFCBD5E1);
const _kSlate400     = Color(0xFF94A3B8);
const _kSlate500     = Color(0xFF64748B);

// Glass input: rgba(25, 34, 51, 0.6) bg / rgba(49, 68, 103, 0.5) border
const _kInputBg     = Color(0x99192233);
const _kInputBorder = Color(0x80314467);

// Spacing scale: 8 · 16 · 20 · 24 · 32 · 48 · 64
const double _sp8  = 8;
const double _sp12 = 12;
const double _sp16 = 16;
const double _sp20 = 20;
const double _sp32 = 32;
const double _sp48 = 48;
const double _sp64 = 64;

// ─────────────────────────────────────────────────────────────────────────────
// AuthScreen — Login screen (Step 4)
// Login button is a placeholder: prints 'login tapped', no backend call.
// ─────────────────────────────────────────────────────────────────────────────
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _obscurePassword = true;
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  Future<void> _onLoginTap() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email and password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService().login(email: email, password: password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      await StorageService().saveToken(result['access_token'] as String);
      await StorageService().saveIdVerified(result['id_verified'] ?? false);
      await StorageService().saveUserEmail(email);
      if (!mounted) return;
      final idVerified = result['id_verified'] as bool? ?? false;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => idVerified
              ? const MainShell()
              : IdVerificationScreen(email: email),
        ),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String? ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size    = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: _kBackground,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: background ──────────────────────────────────────────
          const _AuthBackdrop(),

          // ── Layer 2: decorative blobs ────────────────────────────────────
          // HTML: -bottom-20 -left-20 size-64 bg-primary/10 blur-[80px]
          const _AuthBlob(
            bottom: -80, left: -80,
            diameter: 256, color: _kPrimary, opacity: 0.10, blurSigma: 40,
          ),
          // HTML: -top-20 -right-20 size-64 bg-accent-blue/5 blur-[80px]
          const _AuthBlob(
            top: -80, right: -80,
            diameter: 256, color: _kAccentBlue, opacity: 0.05, blurSigma: 40,
          ),

          // ── Layer 3: scrollable content ──────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height - padding.top - padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header: logo + brand (pt-16 pb-8) ─────────────
                      const Padding(
                        padding: EdgeInsets.only(top: _sp64, bottom: _sp32),
                        child: _LogoSection(),
                      ),

                      // ── Title (pt-6 pb-10) ────────────────────────────
                      const Padding(
                        padding: EdgeInsets.fromLTRB(
                            _sp32, 0, _sp32, _sp32 + _sp8),
                        child: _TitleSection(),
                      ),

                      // ── Form ─────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: _sp32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email
                            _inputLabel('EMAIL'),
                            const SizedBox(height: _sp8),
                            _GlassInput(
                              controller:  _emailController,
                              hint:        'Enter your email',
                              prefixIcon:  Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: _sp20),

                            // Password
                            _inputLabel('PASSWORD'),
                            const SizedBox(height: _sp8),
                            _GlassInput(
                              controller:  _passwordController,
                              hint:        'Enter your password',
                              prefixIcon:  Icons.lock_outline,
                              obscureText: _obscurePassword,
                              suffixIcon:  _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              onSuffixTap: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            const SizedBox(height: _sp12),

                            // Forgot password
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                ),
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.manrope(
                                    color:      _kPrimary,
                                    fontSize:   12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: _sp32),

                            // Login button
                            _LoginButton(onTap: _isLoading ? () {} : _onLoginTap, isLoading: _isLoading),
                          ],
                        ),
                      ),

                      // Push register link to bottom
                      const Spacer(),

                      // ── Register link (pb-12) ─────────────────────────
                      Padding(
                        padding: const EdgeInsets.only(bottom: _sp48),
                        child: _RegisterLink(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            color:         _kSlate300,
            fontSize:      11,
            fontWeight:    FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      );
}

// ─── Logo Section ─────────────────────────────────────────────────────────────
class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo card — 75% of splash (128 × 0.75 ≈ 96 px)
        const _SmallLogoCard(),
        const SizedBox(height: _sp16),
        // "iFind" brand text
        RichText(
          text: TextSpan(
            style: GoogleFonts.manrope(
              fontSize:      36,
              fontWeight:    FontWeight.w800,
              letterSpacing: -0.5,
              height:        1.0,
            ),
            children: const [
              TextSpan(text: 'i',    style: TextStyle(color: Colors.white)),
              TextSpan(text: 'Find', style: TextStyle(color: _kPrimary)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Gradient underline: mt-1 h-1 w-10 → 4 px × 40 px
        Container(
          width:  40,
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
}

// ─── Small Logo Card (scale-75 of splash logo) ────────────────────────────────
class _SmallLogoCard extends StatelessWidget {
  const _SmallLogoCard();

  @override
  Widget build(BuildContext context) {
    const double cardSize   = 96.0;
    const double cardRadius = 24.0;
    const double iconSize   = 52.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width:  cardSize + 14,
            height: cardSize + 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cardRadius + 4),
              gradient: LinearGradient(
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
        // Card body
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
                color:      Colors.black.withValues(alpha: 0.40),
                blurRadius: 24,
                offset:     const Offset(0, 12),
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
                          _kPrimary.withValues(alpha: 0.20),
                          Colors.transparent,
                          _kAccentPurple.withValues(alpha: 0.20),
                        ],
                        stops: const [0.0, 0.50, 1.0],
                      ),
                    ),
                  ),
                ),
                // Blurred ring behind pin
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Icon(
                    Icons.radio_button_checked,
                    size:  iconSize * 1.25,
                    color: _kPrimary.withValues(alpha: 0.40),
                  ),
                ),
                // Location pin icon
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
                        color:      Colors.white.withValues(alpha: 0.30),
                        blurRadius: 12,
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

// ─── Title Section ────────────────────────────────────────────────────────────
class _TitleSection extends StatelessWidget {
  const _TitleSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Welcome Back',
          style: GoogleFonts.manrope(
            color:      Colors.white,
            fontSize:   30,
            fontWeight: FontWeight.w700,
            height:     1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: _sp8),
        Text(
          'Login to continue using iFind',
          style: GoogleFonts.manrope(
            color:      _kSlate400,
            fontSize:   14,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Glass Input ──────────────────────────────────────────────────────────────
class _GlassInput extends StatelessWidget {
  const _GlassInput({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.onSuffixTap,
  });

  final TextEditingController controller;
  final String                 hint;
  final IconData               prefixIcon;
  final bool                   obscureText;
  final TextInputType?         keyboardType;
  final IconData?              suffixIcon;
  final VoidCallback?          onSuffixTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color:        _kInputBg,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: _kInputBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: _sp16),
      child: Row(
        children: [
          Icon(prefixIcon, color: _kSlate500, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller:    controller,
              obscureText:   obscureText,
              keyboardType:  keyboardType,
              style: GoogleFonts.manrope(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText:       hint,
                hintStyle:      GoogleFonts.manrope(
                  color: _kSlate500, fontSize: 15,
                ),
                border:         InputBorder.none,
                enabledBorder:  InputBorder.none,
                focusedBorder:  InputBorder.none,
                isDense:        true,
                contentPadding: EdgeInsets.zero,
              ),
              cursorColor: _kPrimary,
            ),
          ),
          if (suffixIcon != null)
            GestureDetector(
              onTap:    onSuffixTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: _sp8),
                child: Icon(suffixIcon, color: _kSlate500, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Login Button ─────────────────────────────────────────────────────────────
class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.onTap, this.isLoading = false});

  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [_kPrimary, _kAccentBlue],
            begin:  Alignment.centerLeft,
            end:    Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color:      _kPrimary.withValues(alpha: 0.40),
              blurRadius: 20,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Login',
                  style: GoogleFonts.manrope(
                    color:      Colors.white,
                    fontSize:   17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Register Link ────────────────────────────────────────────────────────────
class _RegisterLink extends StatelessWidget {
  const _RegisterLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: GoogleFonts.manrope(color: _kSlate400, fontSize: 14),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onTap,
          child: Text(
            'Register',
            style: GoogleFonts.manrope(
              color:      _kAccentBlue,
              fontSize:   14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Background Backdrop ──────────────────────────────────────────────────────
// HTML: radial-gradient(circle at top right, #1e2a4a, #101622)
//       + linear-gradient(180deg, #101622 → #1a1033)
class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        // Base dark navy
        ColoredBox(color: _kBackground),
        // Bottom: linear gradient #101622 → #1a1033
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin:  Alignment.topCenter,
              end:    Alignment.bottomCenter,
              colors: [Color(0xFF101622), Color(0xFF1A1033)],
            ),
          ),
        ),
        // Top-right radial: #1e2a4a light bloom
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(1.0, -1.0),
              radius: 1.4,
              colors: [Color(0xFF1E2A4A), Color(0x00101622)],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Ambient Blob ─────────────────────────────────────────────────────────────
class _AuthBlob extends StatelessWidget {
  const _AuthBlob({
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.diameter,
    required this.color,
    required this.opacity,
    required this.blurSigma,
  });

  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final double  diameter;
  final Color   color;
  final double  opacity;
  final double  blurSigma;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top:    top,
      right:  right,
      bottom: bottom,
      left:   left,
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
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
