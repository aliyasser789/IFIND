import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'auth_screen.dart';
import 'change_display_name_screen.dart';
import 'change_password_screen.dart';
import 'change_username_screen.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kPrimary       = Color(0xFF135BEC);
const _kAccentPurple  = Color(0xFF8B5CF6);
const _kTertiary      = Color(0xFF00D2FF);
const _kBackground    = Color(0xFF101622);
const _kCardBg        = Color(0xFF282A32); // surface-container-highest
const _kSlate400      = Color(0xFF94A3B8);
const _kSlate500      = Color(0xFF64748B);
const _kLogoutBg      = Color(0xFF93000A); // error-container
const _kLogoutText    = Color(0xFFFFB4AB); // error

// ─────────────────────────────────────────────────────────────────────────────
// SettingsScreen — full content screen, no AppBar, no bottom nav
// Pushed from HomeScreen via Navigator.push; Android back gesture navigates back
// ─────────────────────────────────────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _fullName = '';
  String _username = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final result = await ApiService().getUserProfile();
    if (!mounted) return;
    setState(() {
      _fullName = (result['full_name'] as String?) ?? '';
      _username = (result['username'] as String?) ?? '';
      _loading  = false;
    });
  }

  Future<void> _logout() async {
    final s = StorageService();
    await s.deleteToken();
    await s.deleteIdVerified();
    await s.deleteUserEmail();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background gradient ─────────────────────────────────────────
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF101622), Color(0xFF1A1435)],
              ),
            ),
          ),

          // ── Ambient glow blobs ──────────────────────────────────────────
          Positioned(
            top: -60, right: -60,
            child: IgnorePointer(
              child: Container(
                width: 280, height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kPrimary.withValues(alpha: 0.10),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80, left: -60,
            child: IgnorePointer(
              child: Container(
                width: 260, height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kAccentPurple.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),

          // ── Main content ────────────────────────────────────────────────
          SafeArea(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: _kPrimary, strokeWidth: 2.5,
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Heading
                        Text(
                          'Settings',
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Manage your account preferences and secure your profile.',
                          style: GoogleFonts.manrope(
                            color: _kSlate400,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Section label
                        Text(
                          'ACCOUNT DETAILS',
                          style: GoogleFonts.manrope(
                            color: _kAccentPurple,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Account card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _kCardBg.withValues(alpha: 0.40),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                _SettingsRow(
                                  iconData:  Icons.badge_outlined,
                                  iconColor: _kPrimary,
                                  title:     'Change Display Name',
                                  subtitle:  _fullName,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ChangeDisplayNameScreen(),
                                    ),
                                  ).then((_) => _loadProfile()),
                                ),
                                const _RowDivider(),
                                _SettingsRow(
                                  iconData:  Icons.alternate_email,
                                  iconColor: _kAccentPurple,
                                  title:     'Change Username',
                                  subtitle:  '@$_username',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ChangeUsernameScreen(),
                                    ),
                                  ).then((_) => _loadProfile()),
                                ),
                                const _RowDivider(),
                                _SettingsRow(
                                  iconData:  Icons.key,
                                  iconColor: _kTertiary,
                                  title:     'Change Password',
                                  subtitle:  'Keep your account secure',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ChangePasswordScreen(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Logout button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout, size: 20),
                            label: Text(
                              'Logout',
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _kLogoutBg.withValues(alpha: 0.20),
                              foregroundColor: _kLogoutText,
                              disabledBackgroundColor:
                                  _kLogoutBg.withValues(alpha: 0.10),
                              side: BorderSide(
                                color: _kLogoutText.withValues(alpha: 0.30),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
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

// ─── Row Divider ──────────────────────────────────────────────────────────────
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ─── Settings Row ─────────────────────────────────────────────────────────────
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.iconData,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData      iconData;
  final Color         iconColor;
  final String        title;
  final String        subtitle;
  final VoidCallback  onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withValues(alpha: 0.05),
        highlightColor: Colors.white.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.20),
                    width: 1,
                  ),
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              // Title + value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.manrope(
                        color: _kSlate400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: _kSlate500, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
