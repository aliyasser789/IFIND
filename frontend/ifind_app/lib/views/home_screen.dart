import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/chat_controller.dart';
import '../providers/user_profile_provider.dart';
import '../services/api_service.dart';
import '../services/badge_service.dart';
import '../services/storage_service.dart';
import 'auth_screen.dart';
import 'chat_screen.dart';

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
// HomeScreen — body content for the Home tab inside MainShell
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onTabSwitch});

  final ValueChanged<int>? onTabSwitch;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _recentItems = [];
  // ignore: unused_field
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _init();
    _unreadCount = BadgeService.badgeCount.value;
    BadgeService.badgeCount.addListener(_onBadgeChanged);
  }

  void _onBadgeChanged() {
    if (mounted) setState(() => _unreadCount = BadgeService.badgeCount.value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final chats = await ChatController().getUserChats();
    if (!mounted) return;
    final unread = await BadgeService.getUnreadMessageCount(chats);
    if (!mounted) return;
    BadgeService.badgeCount.value = unread;
  }

  @override
  void dispose() {
    BadgeService.badgeCount.removeListener(_onBadgeChanged);
    super.dispose();
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

    final fullName = await ApiService().getMe() ?? '';
    if (!mounted) return;

    final name = fullName.isNotEmpty ? fullName : 'User';

    final items = await ApiService().getRecentItems();
    if (!mounted) return;

    setState(() {
      _recentItems = items.take(5).toList();
      _loading = false;
    });
    Provider.of<UserProfileProvider>(context, listen: false).updateName(name);
  }

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
          SafeArea(
            top: false,
            child: Column(
              children: [
                const _HomeHeader(),
                // Scrollable body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome
                        _WelcomeSection(displayName: Provider.of<UserProfileProvider>(context).displayName),
                        const SizedBox(height: 32),

                        // Action cards
                        _ActionCard(
                          title: 'I Found Something',
                          subtitle: 'Report an item you found',
                          icon: Icons.front_hand,
                          accentColor: _kPrimary,
                          onTap: () => widget.onTabSwitch?.call(2),
                        ),
                        const SizedBox(height: 24),
                        _ActionCard(
                          title: 'I Lost Something',
                          subtitle: 'Search for your lost item',
                          icon: Icons.search,
                          accentColor: _kAccentPurple,
                          onTap: () => widget.onTabSwitch?.call(1),
                        ),
                        const SizedBox(height: 32),

                        // Recent near you
                        _RecentSection(
                          items: _recentItems,
                          onSeeAll: () => widget.onTabSwitch?.call(1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
  const _RecentSection({required this.items, this.onSeeAll});

  final List<Map<String, dynamic>> items;
  final VoidCallback? onSeeAll;

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
              onTap: onSeeAll,
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

  List<String> _buildPhotoUrls() {
    final raw = item['photo_url'];
    List<dynamic> paths = [];
    if (raw is List) {
      paths = raw;
    } else if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          paths = decoded;
        } else {
          paths = [raw];
        }
      } catch (_) {
        paths = [raw];
      }
    }
    final itemId = item['id'];
    return paths
        .take(5)
        .map((p) {
          final path = p.toString();
          if (path.isEmpty) return '';
          final filename = path.split('/').last;
          return '$_kBaseUrl/items/photos/$itemId/$filename';
        })
        .where((s) => s.isNotEmpty)
        .toList();
  }

  String _formatDate() {
    final dateStr = item['created_at'] as String?;
    if (dateStr == null) return 'Unknown date';
    try {
      final date = DateTime.parse(
        dateStr.endsWith('Z') ? dateStr : '${dateStr}Z'
      ).toLocal();
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

  Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    try {
      final padded = base64Url.normalize(parts[1]);
      return jsonDecode(utf8.decode(base64Url.decode(padded))) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _openChat(BuildContext context) async {
    final token = await StorageService().getToken();
    if (token == null) return;

    final payload       = _decodeJwtPayload(token);
    final currentUserId = (payload['sub'] as String?) ?? '';

    final itemId   = item['id']?.toString() ?? '';
    final finderId = item['user_id']?.toString() ?? '';

    final chatId = await ChatController().startChat(itemId, finderId, currentUserId);
    if (chatId == null) return;
    // The initiator is opening the chat themselves — mark it seen so they
    // don't see a blue "NEW" sign on their own conversation.
    await BadgeService.saveSeenChatId(chatId);
    if (!context.mounted) return;

    final features     = item['features'];
    final itemName     = (features is Map ? features['description'] as String? : null)
                         ?? (item['name'] as String?) ?? 'Unknown Item';
    final district     = (item['district']   as String?) ?? '';
    final foundDate    = (item['created_at'] as String?) ?? '';
    final itemPhoto    = jsonEncode(_buildPhotoUrls());
    final itemCategory = item['category']?.toString() ?? '';
    final itemFeatures = (features as Map<String, dynamic>?) ?? {};

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId:       chatId,
          itemName:     itemName,
          district:     district,
          foundDate:    foundDate,
          finderId:     finderId,
          itemPhoto:    itemPhoto,
          itemCategory: itemCategory,
          itemFeatures: itemFeatures,
        ),
      ),
    );
  }

  void _showModal(BuildContext context) {
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
                      // Photo carousel with category badge
                      Stack(
                        children: [
                          _CardImageCarousel(
                            urls: _buildPhotoUrls(),
                            height: 240,
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
                                  _openChat(context);
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
                    _CardImageCarousel(urls: _buildPhotoUrls()),
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
                onPressed: () => _openChat(context),
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

// ─── Card Image Carousel ──────────────────────────────────────────────────────
class _CardImageCarousel extends StatefulWidget {
  const _CardImageCarousel({required this.urls, this.height = 180});
  final List<String> urls;
  final double height;

  @override
  State<_CardImageCarousel> createState() => _CardImageCarouselState();
}

class _CardImageCarouselState extends State<_CardImageCarousel> {
  late final PageController _pageCtrl;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          width: double.infinity,
          height: widget.height,
          color: _kSlate900,
          child: const Icon(Icons.image_not_supported_outlined,
              color: _kSlate500, size: 40),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Stack(
        children: [
          SizedBox(
            height: widget.height,
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) => Image.network(
                widget.urls[i],
                width: double.infinity,
                height: widget.height,
                fit: BoxFit.cover,
                loadingBuilder: (c, child, prog) {
                  if (prog == null) return child;
                  return Container(
                    width: double.infinity,
                    height: widget.height,
                    color: _kSlate900,
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: _kPrimary, strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (c, e, s) => Container(
                  width: double.infinity,
                  height: widget.height,
                  color: _kSlate900,
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: _kSlate500, size: 40),
                ),
              ),
            ),
          ),
          if (widget.urls.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.urls.length, (i) {
                  final active = i == _current;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? _kPrimary
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Home Header ─────────────────────────────────────────────────────────────
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
          child: const SafeArea(
            bottom: false,
            child: SizedBox(
              height: 64,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Row(children: []),
              ),
            ),
          ),
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
