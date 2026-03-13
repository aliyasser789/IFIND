import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'email_verification_screen.dart';

// ── Design tokens (identical to auth_screen.dart) ────────────────────────────
const _kPrimary      = Color(0xFF135BEC);
const _kAccentBlue   = Color(0xFF00D2FF);
const _kAccentPurple = Color(0xFF8B5CF6);
const _kBackground   = Color(0xFF101622);
const _kSlate900     = Color(0xFF0F172A);
const _kSlate300     = Color(0xFFCBD5E1);
const _kSlate400     = Color(0xFF94A3B8);
const _kSlate500     = Color(0xFF64748B);
const _kInputBg      = Color(0x99192233);
const _kInputBorder  = Color(0x80314467);

const double _sp8  = 8;
const double _sp16 = 16;
const double _sp20 = 20;
const double _sp24 = 24;
const double _sp32 = 32;
const double _sp48 = 48;

// ─────────────────────────────────────────────────────────────────────────────
// RegisterScreen — Step 5, Baby Step 3
// Calls POST /auth/register and shows result feedback.
// ─────────────────────────────────────────────────────────────────────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController        = TextEditingController();
  final _emailController           = TextEditingController();
  final _fullNameController        = TextEditingController();
  final _ageController             = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword        = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading              = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Client-side validation ────────────────────────────────────────────────
  String? _validate() {
    if (_usernameController.text.trim().isEmpty)          return 'Username is required';
    if (_emailController.text.trim().isEmpty)             return 'Email is required';
    if (_fullNameController.text.trim().isEmpty)          return 'Full name is required';
    if (_ageController.text.trim().isEmpty)               return 'Age is required';
    if (int.tryParse(_ageController.text.trim()) == null) return 'Age must be a number';
    if (_passwordController.text.isEmpty)                 return 'Password is required';
    if (_confirmPasswordController.text.isEmpty)          return 'Please confirm your password';
    if (_passwordController.text != _confirmPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _onRegisterTap() async {
    final error = _validate();
    if (error != null) {
      _showSnackbar(error, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService().register(
        fullName:        _fullNameController.text.trim(),
        age:             int.parse(_ageController.text.trim()),
        email:           _emailController.text.trim(),
        username:        _usernameController.text.trim(),
        password:        _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        final email = _emailController.text.trim();
        await StorageService().savePendingEmail(email);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(email: email),
          ),
        );
      } else {
        _showSnackbar(result['message'] as String, isError: true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackbar('Something went wrong. Please try again.', isError: true);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.manrope(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape:    RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(_sp16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size    = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor:        _kBackground,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: background ───────────────────────────────────────────
          const _RegBackdrop(),

          // ── Layer 2: ambient blobs ────────────────────────────────────────
          const _RegBlob(
            bottom: -80, left: -80,
            diameter: 256, color: _kPrimary,
            opacity: 0.10, blurSigma: 40,
          ),
          const _RegBlob(
            top: -80, right: -80,
            diameter: 256, color: _kAccentPurple,
            opacity: 0.07, blurSigma: 40,
          ),

          // ── Layer 3: scrollable content ───────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      size.height - padding.top - padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Back arrow ───────────────────────────────────
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: _sp16, top: _sp8),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: _kSlate300,
                              size:  20,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),

                      // ── Logo ─────────────────────────────────────────
                      const Padding(
                        padding: EdgeInsets.only(
                            top: _sp20, bottom: _sp24),
                        child: _RegLogoSection(),
                      ),

                      // ── Title ─────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            _sp32, 0, _sp32, _sp32),
                        child: Text(
                          'Create Account',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            color:      Colors.white,
                            fontSize:   30,
                            fontWeight: FontWeight.w700,
                            height:     1.2,
                          ),
                        ),
                      ),

                      // ── Form ─────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: _sp32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _label('Username'),
                            const SizedBox(height: _sp8),
                            _RegInput(
                              controller:  _usernameController,
                              hint:        'Enter username',
                              inputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: _sp20),

                            _label('Email'),
                            const SizedBox(height: _sp8),
                            _RegInput(
                              controller:   _emailController,
                              hint:         'Enter email',
                              keyboardType: TextInputType.emailAddress,
                              inputAction:  TextInputAction.next,
                            ),
                            const SizedBox(height: _sp20),

                            _label('Full Name'),
                            const SizedBox(height: _sp8),
                            _RegInput(
                              controller:  _fullNameController,
                              hint:        'Enter full name',
                              inputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: _sp20),

                            _label('Age'),
                            const SizedBox(height: _sp8),
                            _RegInput(
                              controller:   _ageController,
                              hint:         'Enter age',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              inputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: _sp20),

                            _label('Password'),
                            const SizedBox(height: _sp8),
                            _RegInput(
                              controller:  _passwordController,
                              hint:        'Create password',
                              obscureText: _obscurePassword,
                              suffixIcon:  _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              onSuffixTap: () => setState(() =>
                                  _obscurePassword = !_obscurePassword),
                              inputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: _sp20),

                            _label('Confirm Password'),
                            const SizedBox(height: _sp8),
                            _RegInput(
                              controller:  _confirmPasswordController,
                              hint:        'Confirm password',
                              obscureText: _obscureConfirmPassword,
                              suffixIcon:  _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              onSuffixTap: () => setState(() =>
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword),
                              inputAction: TextInputAction.done,
                            ),
                            const SizedBox(height: _sp32),

                            // ── Register Button ──────────────────────
                            _RegisterButton(
                              isLoading: _isLoading,
                              onTap: _isLoading ? null : _onRegisterTap,
                            ),
                            const SizedBox(height: _sp24),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // ── Login link ────────────────────────────────────
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: _sp48),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account?',
                              style: GoogleFonts.manrope(
                                  color: _kSlate400, fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.of(context).pop(),
                              child: Text(
                                'Login',
                                style: GoogleFonts.manrope(
                                  color:      _kAccentBlue,
                                  fontSize:   14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text,
          style: GoogleFonts.manrope(
            color:      _kSlate300,
            fontSize:   13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

// ─── Logo Section ─────────────────────────────────────────────────────────────
class _RegLogoSection extends StatelessWidget {
  const _RegLogoSection();

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
              TextSpan(
                  text: 'i', style: TextStyle(color: Colors.white)),
              TextSpan(
                  text: 'Find', style: TextStyle(color: _kPrimary)),
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
                  imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
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

// ─── Register Input Field ─────────────────────────────────────────────────────
class _RegInput extends StatelessWidget {
  const _RegInput({
    required this.controller,
    required this.hint,
    this.obscureText        = false,
    this.keyboardType,
    this.inputFormatters,
    this.suffixIcon,
    this.onSuffixTap,
    this.inputAction        = TextInputAction.next,
  });

  final TextEditingController      controller;
  final String                     hint;
  final bool                       obscureText;
  final TextInputType?             keyboardType;
  final List<TextInputFormatter>?  inputFormatters;
  final IconData?                  suffixIcon;
  final VoidCallback?              onSuffixTap;
  final TextInputAction            inputAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color:        _kInputBg,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: _kInputBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: _sp16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller:      controller,
              obscureText:     obscureText,
              keyboardType:    keyboardType,
              textInputAction: inputAction,
              inputFormatters: inputFormatters,
              style: GoogleFonts.manrope(
                  color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.manrope(
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

// ─── Register Button ──────────────────────────────────────────────────────────
class _RegisterButton extends StatelessWidget {
  const _RegisterButton({
    required this.isLoading,
    required this.onTap,
  });

  final bool          isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null;
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
                    _kAccentBlue.withValues(alpha: 0.5),
                  ]
                : [_kPrimary, _kAccentBlue],
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
                  'Create Account',
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

// ─── Background Backdrop ──────────────────────────────────────────────────────
class _RegBackdrop extends StatelessWidget {
  const _RegBackdrop();

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
class _RegBlob extends StatelessWidget {
  const _RegBlob({
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
