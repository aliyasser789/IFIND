import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import 'forgot_password_reset_screen.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kPrimary      = Color(0xFF135BEC);
const _kAccentPurple = Color(0xFF8B5CF6);
const _kBackground   = Color(0xFF101622);
const _kSlate900     = Color(0xFF0F172A);
const _kSlate400     = Color(0xFF94A3B8);
const _kSlate500     = Color(0xFF64748B);

const double _sp8  = 8;
const double _sp16 = 16;
const double _sp24 = 24;
const double _sp32 = 32;
const double _sp48 = 48;

// ─────────────────────────────────────────────────────────────────────────────
// ForgotPasswordOtpScreen — Step 2 of 3
// ─────────────────────────────────────────────────────────────────────────────
class ForgotPasswordOtpScreen extends StatefulWidget {
  /// The email address the code was sent to (passed from Screen 1).
  final String email;

  const ForgotPasswordOtpScreen({super.key, required this.email});

  @override
  State<ForgotPasswordOtpScreen> createState() =>
      _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  static const int _otpLength = 6;

  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  bool _isLoading = false;

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _otp =>
      _controllers.map((c) => c.text).join();

  Future<void> _onVerify() async {
    if (_otp.length < _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final result = await ApiService().verifyResetOtp(widget.email, _otp);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result['success'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ForgotPasswordResetScreen(email: widget.email),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String? ?? 'OTP verification failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onResend() {
    // TODO: call API to resend OTP
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Code resent to ${widget.email}',
          style: GoogleFonts.manrope(),
        ),
        backgroundColor: _kPrimary,
      ),
    );
  }

  void _handleInput(int index, String value) {
    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  void _handleBackspace(int index, String value) {
    if (value.isEmpty && index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      setState(() {});
    }
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
          // ── Background ────────────────────────────────────────────────────
          const _OtpBackdrop(),

          // ── Ambient blobs ─────────────────────────────────────────────────
          const _OtpBlob(
            top: -80, left: -80,
            diameter: 160, color: _kPrimary,
            opacity: 0.10, blurSigma: 40,
          ),
          const _OtpBlob(
            bottom: -80, right: -80,
            diameter: 160, color: _kAccentPurple,
            opacity: 0.10, blurSigma: 40,
          ),

          // ── Content ───────────────────────────────────────────────────────
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
                        child: _OtpLogoSection(),
                      ),

                      // Title + subtitle
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            _sp32, 0, _sp32, _sp32),
                        child: _OtpTitleSection(email: widget.email),
                      ),

                      // OTP boxes
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: _sp32),
                        child: _OtpGrid(
                          controllers: _controllers,
                          focusNodes:  _focusNodes,
                          onInput:     _handleInput,
                          onBackspace: _handleBackspace,
                        ),
                      ),
                      const SizedBox(height: _sp32),

                      // Verify button
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: _sp32),
                        child: _VerifyButton(
                          onTap:     _isLoading ? () {} : _onVerify,
                          isLoading: _isLoading,
                        ),
                      ),

                      // Resend link
                      Padding(
                        padding: const EdgeInsets.only(top: _sp24, bottom: _sp32),
                        child: _ResendLink(onResend: _onResend),
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
}

// ─── Logo Section ─────────────────────────────────────────────────────────────
class _OtpLogoSection extends StatelessWidget {
  const _OtpLogoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _OtpLogoCard(),
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
class _OtpLogoCard extends StatelessWidget {
  const _OtpLogoCard();

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
class _OtpTitleSection extends StatelessWidget {
  const _OtpTitleSection({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Forgot Password',
          style: GoogleFonts.manrope(
            color:      Colors.white,
            fontSize:   32,
            fontWeight: FontWeight.w700,
            height:     1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: _sp8),
        Text(
          'Enter the 6-digit code sent to\nyour email',
          style: GoogleFonts.manrope(
            color:      _kSlate400,
            fontSize:   15,
            fontWeight: FontWeight.w500,
            height:     1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── OTP Grid ─────────────────────────────────────────────────────────────────
class _OtpGrid extends StatelessWidget {
  const _OtpGrid({
    required this.controllers,
    required this.focusNodes,
    required this.onInput,
    required this.onBackspace,
  });

  final List<TextEditingController>         controllers;
  final List<FocusNode>                     focusNodes;
  final void Function(int index, String v)  onInput;
  final void Function(int index, String v)  onBackspace;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        controllers.length,
        (i) => _OtpBox(
          controller: controllers[i],
          focusNode:  focusNodes[i],
          onChanged: (v) => onInput(i, v),
          onBackspace: (v) => onBackspace(i, v),
        ),
      ),
    );
  }
}

// ─── Single OTP Box ───────────────────────────────────────────────────────────
class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  final TextEditingController      controller;
  final FocusNode                  focusNode;
  final ValueChanged<String>       onChanged;
  final ValueChanged<String>       onBackspace;

  @override
  Widget build(BuildContext context) {
    final boxSize = (MediaQuery.of(context).size.width - 64 - 40) / 6;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width:  boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: controller.text.isNotEmpty
            ? _kPrimary.withValues(alpha: 0.15)
            : const Color(0x661E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: controller.text.isNotEmpty
              ? _kPrimary.withValues(alpha: 0.60)
              : Colors.white.withValues(alpha: 0.10),
          width: 1.5,
        ),
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            onBackspace(controller.text);
          }
        },
        child: TextField(
          controller:     controller,
          focusNode:      focusNode,
          textAlign:      TextAlign.center,
          keyboardType:   TextInputType.number,
          maxLength:      1,
          style: GoogleFonts.manrope(
            color:      Colors.white,
            fontSize:   20,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            counterText:    '',
            border:         InputBorder.none,
            enabledBorder:  InputBorder.none,
            focusedBorder:  InputBorder.none,
            isDense:        true,
            contentPadding: EdgeInsets.zero,
            hintText:       '•',
            hintStyle: GoogleFonts.manrope(
              color:      _kSlate500,
              fontSize:   20,
              fontWeight: FontWeight.w700,
            ),
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          cursorColor:     _kPrimary,
          onChanged:       onChanged,
        ),
      ),
    );
  }
}

// ─── Verify Button ────────────────────────────────────────────────────────────
class _VerifyButton extends StatelessWidget {
  const _VerifyButton({required this.onTap, this.isLoading = false});
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
                  'Verify',
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

// ─── Resend Link ──────────────────────────────────────────────────────────────
class _ResendLink extends StatelessWidget {
  const _ResendLink({required this.onResend});
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive the code?",
          style: GoogleFonts.manrope(
            color:      _kSlate400,
            fontSize:   13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onResend,
          child: Text(
            'Resend',
            style: GoogleFonts.manrope(
              color:      _kPrimary,
              fontSize:   13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Background ───────────────────────────────────────────────────────────────
class _OtpBackdrop extends StatelessWidget {
  const _OtpBackdrop();

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
class _OtpBlob extends StatelessWidget {
  const _OtpBlob({
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
