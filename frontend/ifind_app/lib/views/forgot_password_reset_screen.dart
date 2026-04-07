import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import 'auth_screen.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kPrimary      = Color(0xFF135BEC);
const _kAccentPurple = Color(0xFF8B5CF6);
const _kBackground   = Color(0xFF101622);
const _kSlate900     = Color(0xFF0F172A);
const _kSurface      = Color(0xFF151C2D);   // surface-container
const _kSlate300     = Color(0xFFCBD5E1);
const _kSlate400     = Color(0xFF94A3B8);
const _kSlate500     = Color(0xFF64748B);
const _kOutline      = Color(0xFF334155);

const double _sp8  = 8;
const double _sp16 = 16;

const double _sp32 = 32;
const double _sp48 = 48;

// ─────────────────────────────────────────────────────────────────────────────
// ForgotPasswordResetScreen — Step 3 of 3
// ─────────────────────────────────────────────────────────────────────────────
class ForgotPasswordResetScreen extends StatefulWidget {
  const ForgotPasswordResetScreen({super.key, required this.email});

  final String email;

  @override
  State<ForgotPasswordResetScreen> createState() =>
      _ForgotPasswordResetScreenState();
}

class _ForgotPasswordResetScreenState
    extends State<ForgotPasswordResetScreen> {
  final _newPasswordController     = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  bool _isLoading      = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onReset() async {
    final newPw  = _newPasswordController.text;
    final confPw = _confirmPasswordController.text;

    if (newPw.isEmpty || confPw.isEmpty) {
      _showSnack('Please fill in both password fields', Colors.red);
      return;
    }
    if (newPw.length < 8) {
      _showSnack('Password must be at least 8 characters', Colors.red);
      return;
    }
    if (newPw != confPw) {
      _showSnack('Passwords do not match', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    final result = await ApiService().resetPassword(widget.email, newPw, confPw);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result['success'] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    } else {
      _showSnack(result['message'] as String? ?? 'Password reset failed', Colors.red);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.manrope()),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size    = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: _kBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.only(left: _sp16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color:        Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size:  18,
            ),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background ──────────────────────────────────────────────────
          const _RpBackdrop(),

          // ── Ambient blobs ────────────────────────────────────────────────
          const _RpBlob(
            top: -80, left: -80,
            diameter: 300, color: _kPrimary,
            opacity: 0.15, blurSigma: 40,
          ),
          const _RpBlob(
            bottom: 0, right: -80,
            diameter: 300, color: _kAccentPurple,
            opacity: 0.10, blurSigma: 40,
          ),

          // ── Content ──────────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height - padding.top - padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      const Padding(
                        padding: EdgeInsets.only(top: _sp48, bottom: _sp32),
                        child: _RpLogoSection(),
                      ),

                      // Title + subtitle
                      const Padding(
                        padding: EdgeInsets.fromLTRB(
                            _sp32, 0, _sp32, _sp32),
                        child: _RpTitleSection(),
                      ),

                      // Form fields
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: _sp32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // New Password
                            _inputLabel('New Password'),
                            const SizedBox(height: _sp8),
                            _RpPasswordInput(
                              controller:  _newPasswordController,
                              hint:        '••••••',
                              obscureText: _obscureNew,
                              onToggle: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                            ),
                            const SizedBox(height: _sp16),

                            // Confirm Password
                            _inputLabel('Confirm Password'),
                            const SizedBox(height: _sp8),
                            _RpPasswordInput(
                              controller:  _confirmPasswordController,
                              hint:        '••••••••',
                              obscureText: _obscureConfirm,
                              onToggle: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                            const SizedBox(height: _sp32),

                            // Reset button
                            _ResetButton(
                              onTap:     _isLoading ? () {} : _onReset,
                              isLoading: _isLoading,
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),
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
            color:      _kSlate300,
            fontSize:   13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

// ─── Logo Section ─────────────────────────────────────────────────────────────
class _RpLogoSection extends StatelessWidget {
  const _RpLogoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _RpLogoCard(),
        const SizedBox(height: _sp16),
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

// ─── Logo Card ────────────────────────────────────────────────────────────────
class _RpLogoCard extends StatelessWidget {
  const _RpLogoCard();

  static const double _size   = 88.0;
  static const double _radius = 22.0;
  static const double _icon   = 48.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: _size + 14, height: _size + 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius + 4),
              gradient: LinearGradient(
                begin:  Alignment.bottomLeft,
                end:    Alignment.topRight,
                colors: [
                  _kPrimary.withValues(alpha: 0.40),
                  _kAccentPurple.withValues(alpha: 0.40),
                ],
              ),
            ),
          ),
        ),
        Container(
          width: _size, height: _size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            color: _kSlate900,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10), width: 1),
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withValues(alpha: 0.40),
                blurRadius: 24,
                offset:     const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: Stack(
              alignment: Alignment.center,
              children: [
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
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Icon(
                    Icons.radio_button_checked,
                    size:  _icon * 1.25,
                    color: _kPrimary.withValues(alpha: 0.40),
                  ),
                ),
                ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (b) => const RadialGradient(
                    center: Alignment(0, -0.3),
                    radius: 0.65,
                    colors: [Color(0xFFFFFFFF), Color(0xFFD0DEFF)],
                  ).createShader(b),
                  child: Icon(
                    Icons.location_on,
                    size:  _icon,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color:      Colors.white.withValues(alpha: 0.30),
                        blurRadius: 12,
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
class _RpTitleSection extends StatelessWidget {
  const _RpTitleSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Reset Password',
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
          'Enter your new password',
          style: GoogleFonts.manrope(
            color:      _kSlate400,
            fontSize:   15,
            fontWeight: FontWeight.w500,
            height:     1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Password Input ───────────────────────────────────────────────────────────
class _RpPasswordInput extends StatelessWidget {
  const _RpPasswordInput({
    required this.controller,
    required this.hint,
    required this.obscureText,
    required this.onToggle,
  });

  final TextEditingController controller;
  final String                 hint;
  final bool                   obscureText;
  final VoidCallback           onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _kOutline.withValues(alpha: 0.20),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: _sp16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller:  controller,
              obscureText: obscureText,
              style: GoogleFonts.manrope(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText:       hint,
                hintStyle:      GoogleFonts.manrope(
                  color:    _kSlate500.withValues(alpha: 0.50),
                  fontSize: 15,
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
          GestureDetector(
            onTap:    onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(left: _sp8),
              child: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _kSlate500,
                size:  20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reset Password Button ────────────────────────────────────────────────────
class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.onTap, this.isLoading = false});
  final VoidCallback onTap;
  final bool         isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _kPrimary,
          boxShadow: [
            BoxShadow(
              color:        _kPrimary.withValues(alpha: 0.30),
              blurRadius:   16,
              spreadRadius: 0,
              offset:       const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  'Reset Password',
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

// ─── Background ───────────────────────────────────────────────────────────────
class _RpBackdrop extends StatelessWidget {
  const _RpBackdrop();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: _kBackground),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin:  Alignment.topCenter,
              end:    Alignment.bottomCenter,
              colors: [Color(0xFF101622), Color(0xFF1A1435)],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Ambient Blob ─────────────────────────────────────────────────────────────
class _RpBlob extends StatelessWidget {
  const _RpBlob({
    this.top, this.right, this.bottom, this.left,
    required this.diameter,
    required this.color,
    required this.opacity,
    required this.blurSigma,
  });

  final double? top, right, bottom, left;
  final double  diameter, opacity, blurSigma;
  final Color   color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, right: right, bottom: bottom, left: left,
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter:
              ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            width: diameter, height: diameter,
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
