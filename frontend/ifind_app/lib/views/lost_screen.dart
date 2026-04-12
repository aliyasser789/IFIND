import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import 'chat_list_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF135BEC);
const _kAccentPurple = Color(0xFF8B5CF6);
const _kBackground = Color(0xFF101622);
const _kSlate900 = Color(0xFF0F172A);
const _kSlate400 = Color(0xFF94A3B8);
const _kSlate500 = Color(0xFF64748B);
const _kCardBg = Color(0xFF1E2A3A);

// ─────────────────────────────────────────────────────────────────────────────
// LostScreen
// ─────────────────────────────────────────────────────────────────────────────
class LostScreen extends StatefulWidget {
  const LostScreen({super.key});

  @override
  State<LostScreen> createState() => _LostScreenState();
}

class _LostScreenState extends State<LostScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedDistrict;
  String? _selectedCategory;
  List<String> _districts = [];
  List<String> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    final api = ApiService();
    final results = await Future.wait([api.getDistricts(), api.getCategories()]);
    if (mounted) {
      setState(() {
        _districts = results[0];
        _categories = results[1];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────
          const _LostHeader(),

          // ── Scrollable body ──────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _kPrimary))
                : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title section
                  Text(
                    'I Lost Something',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Search or browse found items near you',
                    style: GoogleFonts.manrope(
                      color: _kSlate400,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Search bar
                  _buildSearchBar(),
                  const SizedBox(height: 32),

                  // Filter section
                  _buildFilterSection(),
                  const SizedBox(height: 32),

                  // Recent items
                  _buildRecentItems(),
                ],
              ),
            ),
          ),

          // ── Bottom nav ───────────────────────────────────────────────
          _BottomNavBar(
            onHomeTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            ),
            onChatTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ChatListScreen()),
            ),
            onSettingsTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() {}),
        style: GoogleFonts.manrope(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search by color, type, brand...',
          hintStyle: GoogleFonts.manrope(color: _kSlate400, fontSize: 15),
          prefixIcon: const Icon(Icons.search, color: _kSlate400, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FILTER BY',
          style: GoogleFonts.manrope(
            color: _kSlate400,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),

        // District chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _districts.map((d) {
              final selected = _selectedDistrict == d;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedDistrict = selected ? null : d;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? _kPrimary : _kCardBg,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      d,
                      style: GoogleFonts.manrope(
                        color: selected ? Colors.white : _kSlate400,
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Category chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _categories.map((c) {
              final selected = _selectedCategory == c;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedCategory = selected ? null : c;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? _kPrimary : _kCardBg,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      c,
                      style: GoogleFonts.manrope(
                        color: selected ? Colors.white : _kSlate400,
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Items',
          style: GoogleFonts.manrope(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        // Empty state
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 64),
            child: Column(
              children: [
                const Text(
                  '\u{1F4ED}',
                  style: TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 12),
                Text(
                  'No recent items yet',
                  style: GoogleFonts.manrope(
                    color: _kSlate400,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check back soon!',
                  style: GoogleFonts.manrope(
                    color: _kSlate500,
                    fontSize: 14,
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

// ─── Header with back button + iFind logo ────────────────────────────────────
class _LostHeader extends StatelessWidget {
  const _LostHeader();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: _kSlate900.withValues(alpha: 0.40),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.10),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    // ── Back button ──────────────────────────────────────
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),

                    // ── Pin logo (same as home_screen.dart _HomeHeader) ─
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                                colors: [
                                  _kPrimary.withValues(alpha: 0.40),
                                  _kAccentPurple.withValues(alpha: 0.40),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: _kSlate900,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.40),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          _kPrimary.withValues(alpha: 0.20),
                                          Colors.transparent,
                                          _kAccentPurple.withValues(
                                              alpha: 0.20),
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
                                    size: 27,
                                    color: _kPrimary.withValues(alpha: 0.40),
                                  ),
                                ),
                                ShaderMask(
                                  blendMode: BlendMode.srcATop,
                                  shaderCallback: (bounds) =>
                                      const RadialGradient(
                                    center: Alignment(0, -0.3),
                                    radius: 0.65,
                                    colors: [
                                      Color(0xFFFFFFFF),
                                      Color(0xFFD0DEFF),
                                    ],
                                  ).createShader(bounds),
                                  child: Icon(
                                    Icons.location_on,
                                    size: 22,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.white
                                            .withValues(alpha: 0.30),
                                        blurRadius: 12,
                                        offset: Offset.zero,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 12),

                    // ── "iFind" text + gradient underline ────────────────
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.manrope(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              height: 1.0,
                            ),
                            children: const [
                              TextSpan(
                                text: 'i',
                                style: TextStyle(color: Colors.white),
                              ),
                              TextSpan(
                                text: 'Find',
                                style: TextStyle(color: _kPrimary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          width: 32,
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: const LinearGradient(
                              colors: [_kPrimary, _kAccentPurple],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Bottom Nav Bar ──────────────────────────────────────────────────────────
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.onHomeTap,
    required this.onChatTap,
    required this.onSettingsTap,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onChatTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: _kSlate900.withValues(alpha: 0.80),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.10),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home,
                    label: 'HOME',
                    isActive: false,
                    onTap: onHomeTap,
                  ),
                  const _NavItem(
                    icon: Icons.search,
                    label: 'I LOST',
                    isActive: true,
                  ),
                  _NavItem(
                    icon: Icons.chat_bubble_outline,
                    label: 'CHAT',
                    isActive: false,
                    onTap: onChatTap,
                  ),
                  _NavItem(
                    icon: Icons.settings_outlined,
                    label: 'SETTINGS',
                    isActive: false,
                    onTap: onSettingsTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _kPrimary : _kSlate400;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.manrope(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
