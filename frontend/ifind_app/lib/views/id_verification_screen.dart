import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ifind_app/services/api_service.dart';
import 'package:ifind_app/services/storage_service.dart';
import 'package:ifind_app/views/onboarding_screen.dart';

// ── Design tokens (identical palette to all other screens) ───────────────────
const _kPrimary      = Color(0xFF135BEC);
const _kAccentPurple = Color(0xFF8B5CF6);
const _kBackground   = Color(0xFF101622);
const _kSlate900     = Color(0xFF0F172A);
const _kSlate300     = Color(0xFFCBD5E1);
const _kSlate400     = Color(0xFF94A3B8);
const _kSlate500     = Color(0xFF64748B);
const _kInputBorder  = Color(0x80314467);

const double _sp8  = 8;
const double _sp16 = 16;
const double _sp24 = 24;
const double _sp32 = 32;
const double _sp48 = 48;

// ─────────────────────────────────────────────────────────────────────────────
// IdVerificationScreen
// Shown after email verification is complete.
// ─────────────────────────────────────────────────────────────────────────────
class IdVerificationScreen extends StatefulWidget {
  const IdVerificationScreen({super.key, required this.email});

  final String email;

  @override
  State<IdVerificationScreen> createState() => _IdVerificationScreenState();
}

class _IdVerificationScreenState extends State<IdVerificationScreen> {
  final _picker     = ImagePicker();
  final _apiService = ApiService();

  File? _frontImage;
  File? _backImage;
  bool  _isLoading = false;

  Future<void> _pickFront() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) setState(() => _frontImage = File(picked.path));
  }

  Future<void> _pickBack() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) setState(() => _backImage = File(picked.path));
  }

  Future<void> _submit() async {
    if (_frontImage == null) {
      _showError('Please take a photo of the front of your ID');
      return;
    }
    if (_backImage == null) {
      _showError('Please take a photo of the back of your ID');
      return;
    }

    setState(() => _isLoading = true);

    final result = await _apiService.verifyId(
      email: widget.email,
      imageFile: _frontImage!,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true && result['verified'] == true) {
      // Token is issued here for the first time — both verifications complete.
      final token = result['access_token'] as String?;
      if (token != null) {
        await StorageService().saveToken(token);
      }
      await _apiService.uploadIdBack(imageFile: _backImage!);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } else {
      final error = result['error'] as String? ??
          (result['verified'] == false
              ? 'ID could not be verified. Please try again with a clearer photo.'
              : 'Something went wrong. Please try again.');
      _showError(error);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.manrope(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:          _kBackground,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: background ─────────────────────────────────────────
          const _IdBackdrop(),

          // ── Layer 2: ambient blobs ──────────────────────────────────────
          const _IdBlob(
            bottom: -80, left: -80,
            diameter: 256, color: _kPrimary,
            opacity: 0.10, blurSigma: 40,
          ),
          const _IdBlob(
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
                padding: const EdgeInsets.symmetric(horizontal: _sp32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Back button ─────────────────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 0, top: _sp8),
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

                    const SizedBox(height: _sp16),

                    // ── Logo + brand ────────────────────────────────────
                    const _IdLogoSection(),
                    const SizedBox(height: _sp32),

                    // ── Heading ─────────────────────────────────────────
                    Text(
                      'ID Verification',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        color:      Colors.white,
                        fontSize:   28,
                        fontWeight: FontWeight.w700,
                        height:     1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Subtitle ────────────────────────────────────────
                    Text(
                      'Upload a photo of your national ID to verify your identity',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        color:    _kSlate400,
                        fontSize: 14,
                        height:   1.5,
                      ),
                    ),
                    const SizedBox(height: _sp48),

                    // ── Front ID upload ─────────────────────────────────
                    _UploadCard(
                      label:    'Front of ID',
                      icon:     Icons.credit_card_rounded,
                      captured: _frontImage != null,
                      onTap:    _isLoading ? null : _pickFront,
                    ),
                    const SizedBox(height: _sp16),

                    // ── Back ID upload ──────────────────────────────────
                    _UploadCard(
                      label:    'Back of ID',
                      icon:     Icons.credit_card_off_rounded,
                      captured: _backImage != null,
                      onTap:    _isLoading ? null : _pickBack,
                    ),
                    const SizedBox(height: _sp48),

                    // ── Submit button ───────────────────────────────────
                    _IdSubmitButton(
                      onTap:     _isLoading ? null : _submit,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 12),

                    // ── Lighting hint ────────────────────────────────────
                    Text(
                      'Please ensure good lighting when taking your ID photo for accurate scanning',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        color:    Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: _sp24),
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

// ─── Upload Card ──────────────────────────────────────────────────────────────
class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.captured,
  });

  final String      label;
  final IconData    icon;
  final VoidCallback? onTap;
  final bool        captured;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color:        const Color(0x99192233),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: captured ? _kPrimary : _kInputBorder,
            width: captured ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            captured
                ? const Icon(Icons.check_circle_rounded, color: _kPrimary, size: 36)
                : Icon(icon, color: _kPrimary, size: 36),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.manrope(
                color:      _kSlate300,
                fontSize:   14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              captured ? 'Photo captured ✓' : 'Tap to take photo',
              style: GoogleFonts.manrope(
                color:    captured ? _kPrimary : _kSlate500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Submit Button ────────────────────────────────────────────────────────────
class _IdSubmitButton extends StatelessWidget {
  const _IdSubmitButton({required this.onTap, required this.isLoading});

  final VoidCallback? onTap;
  final bool          isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [_kPrimary, Color(0xFF00D2FF)],
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
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Submit ID',
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

// ─── Logo Section ─────────────────────────────────────────────────────────────
class _IdLogoSection extends StatelessWidget {
  const _IdLogoSection();

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

// ─── Background Backdrop ──────────────────────────────────────────────────────
class _IdBackdrop extends StatelessWidget {
  const _IdBackdrop();

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
class _IdBlob extends StatelessWidget {
  const _IdBlob({
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
