import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'id_verification_screen.dart';

// ── Design tokens (identical palette to all other screens) ───────────────────
const _kPrimary      = Color(0xFF135BEC);
const _kAccentPurple = Color(0xFF8B5CF6);
const _kBackground   = Color(0xFF101622);
const _kSlate900     = Color(0xFF0F172A);
const _kSlate400     = Color(0xFF94A3B8);
const _kSlate500     = Color(0xFF64748B);
const _kInputBg      = Color(0x99192233);
const _kInputBorder  = Color(0x80314467);

const double _sp8  = 8;
const double _sp16 = 16;
const double _sp24 = 24;
const double _sp32 = 32;
const double _sp48 = 48;

// ─────────────────────────────────────────────────────────────────────────────
// EmailVerificationScreen
// Shown after register and when app reopens with a pending unverified email.
// Back navigation is blocked — the only exit is a successful verification.
// ─────────────────────────────────────────────────────────────────────────────
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key, required this.email});

  final String email;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying  = false;
  bool _isResending  = false;
  int  _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Automatically send the code as soon as the screen opens.
    _sendCode();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  String get _code => _controllers.map((c) => c.text).join();

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) t.cancel();
      });
    });
  }

  // ── API calls ────────────────────────────────────────────────────────────────
  Future<void> _sendCode() async {
    if (_isResending) return;
    setState(() => _isResending = true);

    final result =
        await ApiService().sendVerificationCode(email: widget.email);
    if (!mounted) return;
    setState(() => _isResending = false);

    if (result['success'] == true) {
      _startCooldown();
      _showSnackbar('Code sent to ${widget.email}', isError: false);
    } else {
      _showSnackbar(result['message'] as String, isError: true);
    }
  }

  Future<void> _onVerifyTap() async {
    final code = _code;
    if (code.length != 6) {
      _showSnackbar('Please enter the complete 6-digit code', isError: true);
      return;
    }

    setState(() => _isVerifying = true);
    final result =
        await ApiService().verifyEmail(email: widget.email, code: code);
    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (result['success'] == true) {
      // Save JWT so ID verification screen can attach it to its request.
      final token = result['access_token'] as String?;
      if (token != null) {
        await StorageService().saveToken(token);
      }
      // Remove pending flag — email is now verified.
      await StorageService().deletePendingEmail();
      if (!mounted) return;
      _showSnackbar('Email verified!', isError: false);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const IdVerificationScreen()),
      );
    } else {
      _showSnackbar(result['message'] as String, isError: true);
      for (final c in _controllers) { c.clear(); }
      _focusNodes[0].requestFocus();
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.manrope(color: Colors.white, fontSize: 14),
        ),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
        behavior:  SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(_sp16),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor:        _kBackground,
        resizeToAvoidBottomInset: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Layer 1: background ─────────────────────────────────────────
            const _VerifyBackdrop(),

            // ── Layer 2: ambient blobs ──────────────────────────────────────
            const _VerifyBlob(
              bottom: -80, left: -80,
              diameter: 256, color: _kPrimary,
              opacity: 0.10, blurSigma: 40,
            ),
            const _VerifyBlob(
              top: -80, right: -80,
              diameter: 256, color: _kAccentPurple,
              opacity: 0.07, blurSigma: 40,
            ),

            // ── Layer 3: content ────────────────────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: _sp32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Back button ───────────────────────────────────
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: _sp8),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Color(0xFFCBD5E1),
                              size:  20,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),

                      // Logo + brand
                      const _VerifyLogoSection(),
                      const SizedBox(height: _sp32),

                      // Heading
                      Text(
                        'Email Verification',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          color:      Colors.white,
                          fontSize:   28,
                          fontWeight: FontWeight.w700,
                          height:     1.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Subtitle
                      Text(
                        'Enter the 6-digit code sent to your email',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          color:   _kSlate400,
                          fontSize: 14,
                          height:  1.5,
                        ),
                      ),
                      const SizedBox(height: _sp8),

                      // Email pill
                      Text(
                        widget.email,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          color:      _kPrimary,
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: _sp32 + _sp8),

                      // OTP input row
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          6,
                          (i) => _OtpBox(
                            controller: _controllers[i],
                            focusNode:  _focusNodes[i],
                            onChanged: (value) {
                              if (value.length == 1 && i < 5) {
                                _focusNodes[i + 1].requestFocus();
                              }
                            },
                            onBackspace: () {
                              if (i > 0) {
                                _controllers[i - 1].clear();
                                _focusNodes[i - 1].requestFocus();
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: _sp32 + _sp8),

                      // Verify button
                      _VerifyButton(
                        isLoading: _isVerifying,
                        onTap: _isVerifying ? null : _onVerifyTap,
                      ),
                      const SizedBox(height: _sp24),

                      // Resend section
                      _ResendSection(
                        isLoading: _isResending,
                        cooldown:  _resendCooldown,
                        onTap: (_isVerifying ||
                                _isResending ||
                                _resendCooldown > 0)
                            ? null
                            : _sendCode,
                      ),
                      const SizedBox(height: _sp48),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  }
}

// ─── OTP Box ──────────────────────────────────────────────────────────────────
class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  final TextEditingController controller;
  final FocusNode             focusNode;
  final ValueChanged<String>  onChanged;
  final VoidCallback          onBackspace;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  44,
      height: 56,
      child: Focus(
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty) {
            onBackspace();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller:      controller,
          focusNode:       focusNode,
          textAlign:       TextAlign.center,
          keyboardType:    TextInputType.number,
          maxLength:       1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged:       onChanged,
          style: GoogleFonts.manrope(
            color:      Colors.white,
            fontSize:   20,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled:      true,
            fillColor:   _kInputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:   const BorderSide(color: _kInputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:   const BorderSide(color: _kInputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            ),
          ),
          cursorColor: _kPrimary,
        ),
      ),
    );
  }
}

// ─── Verify Button ────────────────────────────────────────────────────────────
class _VerifyButton extends StatelessWidget {
  const _VerifyButton({required this.isLoading, required this.onTap});

  final bool          isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: disabled
                ? [
                    _kPrimary.withValues(alpha: 0.5),
                    const Color(0xFF00D2FF).withValues(alpha: 0.5),
                  ]
                : [_kPrimary, const Color(0xFF00D2FF)],
            begin: Alignment.centerLeft,
            end:   Alignment.centerRight,
          ),
          boxShadow: disabled
              ? []
              : [
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
                  width:  22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color:       Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Verify Email',
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

// ─── Resend Section ───────────────────────────────────────────────────────────
class _ResendSection extends StatelessWidget {
  const _ResendSection({
    required this.isLoading,
    required this.cooldown,
    required this.onTap,
  });

  final bool          isLoading;
  final int           cooldown;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final canResend = onTap != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive the code?",
          style: GoogleFonts.manrope(
              color: _kSlate400, fontSize: 14),
        ),
        const SizedBox(width: 4),
        if (isLoading)
          const SizedBox(
            width:  14,
            height: 14,
            child: CircularProgressIndicator(
              color: _kPrimary, strokeWidth: 2,
            ),
          )
        else if (cooldown > 0)
          Text(
            'Resend in ${cooldown}s',
            style: GoogleFonts.manrope(
              color:    _kSlate500,
              fontSize: 14,
            ),
          )
        else
          GestureDetector(
            onTap: onTap,
            child: Text(
              'Resend Code',
              style: GoogleFonts.manrope(
                color:      canResend
                    ? _kPrimary
                    : _kSlate500,
                fontSize:   14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Logo Section ─────────────────────────────────────────────────────────────
class _VerifyLogoSection extends StatelessWidget {
  const _VerifyLogoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SmallLogoCard(),
        const SizedBox(height: _sp16),
        RichText(
          text: TextSpan(
            style: GoogleFonts.manrope(
              fontSize:      34,
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

// ─── Small Logo Card ──────────────────────────────────────────────────────────
class _SmallLogoCard extends StatelessWidget {
  const _SmallLogoCard();

  @override
  Widget build(BuildContext context) {
    const double cardSize   = 88.0;
    const double cardRadius = 22.0;
    const double iconSize   = 48.0;

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
                ImageFiltered(
                  imageFilter:
                      ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Icon(
                    Icons.radio_button_checked,
                    size:  iconSize * 1.25,
                    color: _kPrimary.withValues(alpha: 0.40),
                  ),
                ),
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

// ─── Background Backdrop ──────────────────────────────────────────────────────
class _VerifyBackdrop extends StatelessWidget {
  const _VerifyBackdrop();

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
class _VerifyBlob extends StatelessWidget {
  const _VerifyBlob({
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
          imageFilter:
              ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
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
