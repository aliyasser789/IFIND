import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'auth_screen.dart';
import 'chat_list_screen.dart';
import 'found_screen.dart';
import 'lost_screen.dart';
import 'settings_screen.dart';

// ── Design tokens (identical palette to auth_screen.dart / splash_screen.dart) ─
const _kBaseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);
const _kPrimary = Color(0xFF135BEC);
const _kAccentPurple = Color(0xFF8B5CF6);
const _kBackground = Color(0xFF101622);
const _kSlate900 = Color(0xFF0F172A);
const _kSlate400 = Color(0xFF94A3B8);
const _kSlate500 = Color(0xFF64748B);
const _kSlate800 = Color(0xFF1E293B);
const _kCardBg = Color(0xFF1E2A3A);

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _displayName = '';
  bool _loading = true;
  List<Map<String, dynamic>> _recentItems = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await StorageService().getToken();
    if (!mounted) return;

    if (token == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      return;
    }

    final username = await ApiService().getMe() ?? '';
    if (!mounted) return;

    final name = username.isNotEmpty ? username : 'User';

    final items = await ApiService().getRecentItems();
    if (!mounted) return;

    setState(() {
      _displayName = name;
      _recentItems = items.take(5).toList();
      _loading = false;
    });
  }

  void _goToChat() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatListScreen()),
      );

  void _goToSettings() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _kBackground,
        body: Center(
          child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2.5),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _kBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Ambient blobs ────────────────────────────────────────────────
          const _HomeBlob(
            top: -50,
            right: -50,
            diameter: 300,
            color: _kPrimary,
            opacity: 0.15,
          ),
          const _HomeBlob(
            bottom: 100,
            left: -50,
            diameter: 300,
            color: _kAccentPurple,
            opacity: 0.15,
          ),

          // ── Main layout ──────────────────────────────────────────────────
          Column(
            children: [
              // Fixed top header
              const _HomeHeader(),

              // Scrollable body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome
                      _WelcomeSection(displayName: _displayName),
                      const SizedBox(height: 32),

                      // Action cards
                      _ActionCard(
                        title: 'I Found Something',
                        subtitle: 'Report an item you found',
                        icon: Icons.front_hand,
                        accentColor: _kPrimary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FoundScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _ActionCard(
                        title: 'I Lost Something',
                        subtitle: 'Search for your lost item',
                        icon: Icons.search,
                        accentColor: _kAccentPurple,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LostScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Recent near you
                      _RecentSection(items: _recentItems),
                    ],
                  ),
                ),
              ),

              // Fixed bottom nav
              _BottomNavBar(
                onChatTap: _goToChat,
                onSettingsTap: _goToSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Top Header ───────────────────────────────────────────────────────────────
// Compact nav bar — matches the iFind visual identity from auth_screen.dart:
// same location_on icon, same #135bec→#8b5cf6 gradient, same RichText style,
// same gradient underline.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

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
                    // ── Pin logo (matches _SmallLogoCard in auth_screen.dart) ─
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer blurred glow
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
                        // Card body
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
                                // Internal gradient overlay
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
                                // Blurred ring behind pin
                                ImageFiltered(
                                  imageFilter:
                                      ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                                  child: Icon(
                                    Icons.radio_button_checked,
                                    size: 27,
                                    color: _kPrimary.withValues(alpha: 0.40),
                                  ),
                                ),
                                // Location pin with shader
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

                    // ── "iFind" text + gradient underline ─────────────────
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Matches auth_screen.dart _LogoSection: RichText
                        // i=white / Find=_kPrimary, Manrope extrabold
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
                        // Gradient underline — matches auth_screen.dart
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

// ─── Welcome Section ──────────────────────────────────────────────────────────
class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, $displayName',
          style: GoogleFonts.manrope(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'What brings you here today?',
          style: GoogleFonts.manrope(
            color: _kSlate400,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Action Card ──────────────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Card background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: _kSlate800.withValues(alpha: 0.40),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            // Corner glow (top-right)
            Positioned(
              top: -48,
              right: -48,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.20),
                ),
              ),
            ),

            // Content row
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column: icon + text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon box
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.40),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(icon, color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.manrope(
                            color: _kSlate400,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chevron
                  const Icon(
                    Icons.chevron_right,
                    color: _kSlate500,
                    size: 24,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recent Near You Section ──────────────────────────────────────────────────
class _RecentSection extends StatelessWidget {
  const _RecentSection({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent near you',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LostScreen()),
              ),
              behavior: HitTestBehavior.opaque,
              child: Text(
                'SEE ALL',
                style: GoogleFonts.manrope(
                  color: _kPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (items.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'No recent items yet',
                style: GoogleFonts.manrope(
                  color: _kSlate400,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        else
          ...items.map((item) => _HomeItemCard(item: item)),
      ],
    );
  }
}

// ─── Home Item Card ───────────────────────────────────────────────────────────
class _HomeItemCard extends StatelessWidget {
  const _HomeItemCard({required this.item});

  final Map<String, dynamic> item;

  String _buildPhotoUrl() {
    try {
      final photoList = item['photo_url'] as List<dynamic>;
      if (photoList.isEmpty) return '';
      final path = photoList[0] as String;
      final filename = path.split('/').last;
      final itemId = item['id'];
      return '$_kBaseUrl/items/photos/$itemId/$filename';
    } catch (_) {
      return '';
    }
  }

  String _formatDate() {
    final dateStr = item['created_at'] as String?;
    if (dateStr == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final itemDay = DateTime(date.year, date.month, date.day);
      final diff = today.difference(itemDay).inDays;
      if (diff == 0) return 'Found Today';
      if (diff == 1) return 'Found Yesterday';
      if (diff < 7) return 'Found $diff days ago';
      return 'Found ${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'Unknown date';
    }
  }

  void _showModal(BuildContext context) {
    final photoUrl = _buildPhotoUrl();
    final category = item['category'] as String? ?? 'Unknown';
    final features = item['features'];
    final district = item['district'] as String? ?? 'Unknown';
    final dateLabel = _formatDate();

    final featureEntries = <MapEntry<String, String>>[];
    if (features is Map) {
      final fields = <String, dynamic>{
        'Color': features['color'],
        'Brand': features['brand'],
        'Material': features['material'],
        'Size': features['size'],
        'Distinguishing Feature': features['distinguishing_feature'],
        'Description': features['description'],
      };
      for (final e in fields.entries) {
        final v = e.value;
        if (v != null && v.toString().trim().isNotEmpty) {
          featureEntries.add(MapEntry(e.key, v.toString()));
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Drag handle ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // ── Scrollable content ─────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo with category badge
                      Stack(
                        children: [
                          photoUrl.isNotEmpty
                              ? Image.network(
                                  photoUrl,
                                  width: double.infinity,
                                  height: 240,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (c, child, prog) {
                                    if (prog == null) return child;
                                    return Container(
                                      width: double.infinity,
                                      height: 240,
                                      color: _kSlate900,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                            color: _kPrimary, strokeWidth: 2),
                                      ),
                                    );
                                  },
                                  errorBuilder: (c, e, s) => Container(
                                    width: double.infinity,
                                    height: 240,
                                    color: _kSlate900,
                                    child: const Icon(
                                        Icons.image_not_supported_outlined,
                                        color: _kSlate500,
                                        size: 48),
                                  ),
                                )
                              : Container(
                                  width: double.infinity,
                                  height: 240,
                                  color: _kSlate900,
                                  child: const Icon(
                                      Icons.image_not_supported_outlined,
                                      color: _kSlate500,
                                      size: 48),
                                ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _kAccentPurple,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                category,
                                style: GoogleFonts.manrope(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Details section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Item Details',
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (featureEntries.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              ...featureEntries.asMap().entries.map((e) {
                                return Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          e.value.key,
                                          style: GoogleFonts.manrope(
                                            color: _kSlate400,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Flexible(
                                          child: Text(
                                            e.value.value,
                                            style: GoogleFonts.manrope(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (e.key < featureEntries.length - 1)
                                      Divider(
                                          height: 20,
                                          color: Colors.white
                                              .withValues(alpha: 0.08)),
                                  ],
                                );
                              }),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.location_pin,
                                    color: _kSlate400, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  district,
                                  style: GoogleFonts.manrope(
                                      color: _kSlate400, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dateLabel,
                              style: GoogleFonts.manrope(
                                color: _kPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Chat feature coming soon!')),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _kPrimary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'This is mine!',
                                  style: GoogleFonts.manrope(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _buildPhotoUrl();
    final category = item['category'] as String? ?? 'Unknown';
    final features = item['features'];
    final description = (features is Map)
        ? (features['description'] as String? ?? 'No description')
        : 'No description';
    final district = item['district'] as String? ?? 'Unknown';
    final dateLabel = _formatDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tappable area: photo + description + district + date ───────
          GestureDetector(
            onTap: () => _showModal(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo with category badge
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: photoUrl.isNotEmpty
                          ? Image.network(
                              photoUrl,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                              loadingBuilder: (ctx, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  width: double.infinity,
                                  height: 180,
                                  color: _kSlate900,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: _kPrimary,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (ctx, error, stack) => Container(
                                width: double.infinity,
                                height: 180,
                                color: _kSlate900,
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: _kSlate500,
                                  size: 40,
                                ),
                              ),
                            )
                          : Container(
                              width: double.infinity,
                              height: 180,
                              color: _kSlate900,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: _kSlate500,
                                size: 40,
                              ),
                            ),
                    ),
                    // Category badge — top-left overlay
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kAccentPurple,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Description, district, date
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_pin,
                              color: _kSlate400, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            district,
                            style: GoogleFonts.manrope(
                              color: _kSlate400,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateLabel,
                        style: GoogleFonts.manrope(
                          color: _kPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── "This is mine!" button — outside GestureDetector ──────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Chat feature coming soon!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'This is mine!',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
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

// ─── Bottom Nav Bar ───────────────────────────────────────────────────────────
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.onChatTap,
    required this.onSettingsTap,
  });

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
                  // Home — active
                  const _NavItem(
                    icon: Icons.home,
                    label: 'HOME',
                    isActive: true,
                  ),
                  // Chat
                  _NavItem(
                    icon: Icons.chat_bubble_outline,
                    label: 'CHAT',
                    isActive: false,
                    onTap: onChatTap,
                  ),
                  // Settings
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

// ─── Ambient Blob (decorative background blob) ────────────────────────────────
class _HomeBlob extends StatelessWidget {
  const _HomeBlob({
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
  final double diameter;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
          child: Container(
            width: diameter,
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
