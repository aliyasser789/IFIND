import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/chat_controller.dart';
import '../services/api_service.dart';
import '../services/badge_service.dart';
import '../services/storage_service.dart';
import 'chat_screen.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
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
  List<String> _categories = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> _recentItems = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    final api = ApiService();
    final categories = await api.getCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    }
    _loadRecentItems();
  }

  Future<void> _loadRecentItems() async {
    final api = ApiService();
    final items = await api.getRecentItems();
    if (mounted) {
      setState(() {
        _recentItems = items;
      });
    }
  }

  Future<void> _searchItems() async {
    final query = _searchController.text.trim();
    if (query.isEmpty &&
        _selectedDistrict == null &&
        _selectedCategory == null) {
      if (mounted) {
        setState(() {
          _hasSearched = false;
          _searchResults = [];
        });
      }
      return;
    }
    if (mounted) setState(() => _isSearching = true);
    final api = ApiService();
    final result = await api.searchItems(
      keywords: query.isEmpty ? ' ' : query,
      district: _selectedDistrict,
      category: _selectedCategory,
    );
    if (mounted) {
      if (!result['success']) {
        setState(() {
          _isSearching = false;
          _selectedDistrict = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['error'] ?? 'Search failed',
              style: GoogleFonts.manrope(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(result['data']);
          _hasSearched = true;
          _isSearching = false;
        });
      }
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
                ? const Center(
                    child: CircularProgressIndicator(color: _kPrimary))
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
        onChanged: (value) => _searchItems(),
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

  static const _kPresetDistricts = ['Heliopolis', 'Maadi', 'Nasr City', 'New Cairo', 'Zamalek'];

  Future<void> _showDistrictSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _kSlate900,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LostFilterSheet(
        title: 'Select District',
        items: [..._kPresetDistricts, 'Other'],
        current: _selectedDistrict,
      ),
    );
    if (!mounted) return;
    if (selected == 'Other') {
      await _showCustomDistrictDialog();
    } else if (selected != null) {
      setState(() => _selectedDistrict = selected.isEmpty ? null : selected);
      _searchItems();
    }
  }

  Future<void> _showCustomDistrictDialog() async {
    final controller = TextEditingController();
    final typed = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSlate900,
        title: Text(
          'Enter District',
          style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.manrope(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g. Sheikh Zayed',
            hintStyle: GoogleFonts.manrope(color: _kSlate400),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _kSlate400)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _kPrimary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.manrope(color: _kSlate400)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text('Search', style: GoogleFonts.manrope(color: _kPrimary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (typed != null && typed.isNotEmpty && mounted) {
      setState(() => _selectedDistrict = typed);
      _searchItems();
    }
  }

  Future<void> _showCategorySheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _kSlate900,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LostFilterSheet(
        title: 'Select Category',
        items: _categories,
        current: _selectedCategory,
      ),
    );
    if (selected != null && mounted) {
      setState(() => _selectedCategory = selected.isEmpty ? null : selected);
      _searchItems();
    }
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
        _LostDropdownField(
          selected: _selectedDistrict,
          placeholder: 'Select District',
          onTap: _showDistrictSheet,
        ),
        const SizedBox(height: 12),
        _LostDropdownField(
          selected: _selectedCategory,
          placeholder: 'Select Category',
          onTap: _showCategorySheet,
        ),
      ],
    );
  }

  Widget _buildRecentItems() {
    // ── Search results view ──────────────────────────────────────────────────
    if (_hasSearched) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Results (${_searchResults.length} found)',
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (_isSearching)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: CircularProgressIndicator(color: _kPrimary),
              ),
            )
          else if (_searchResults.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 64),
                child: Column(
                  children: [
                    const Text('🔍', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      'No items found',
                      style: GoogleFonts.manrope(
                        color: _kSlate400,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try different search terms',
                      style: GoogleFonts.manrope(
                        color: _kSlate500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._searchResults.map((item) => _ItemCard(item: item)),
        ],
      );
    }

    // ── Recent items view ────────────────────────────────────────────────────
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
        if (_recentItems.isEmpty)
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
          )
        else
          ..._recentItems.map((item) => _ItemCard(item: item)),
      ],
    );
  }
}

// ─── Lost Screen Dropdown Field ──────────────────────────────────────────────
class _LostDropdownField extends StatelessWidget {
  final String? selected;
  final String placeholder;
  final VoidCallback onTap;

  const _LostDropdownField({
    required this.selected,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kSlate400.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected ?? placeholder,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: selected != null ? Colors.white : _kSlate400,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: _kSlate400, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Lost Screen Filter Bottom Sheet ─────────────────────────────────────────
class _LostFilterSheet extends StatelessWidget {
  final String title;
  final List<String> items;
  final String? current;

  const _LostFilterSheet({
    required this.title,
    required this.items,
    this.current,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: _kSlate900,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: items.length + 1,
                  separatorBuilder: (_, __) => Divider(
                      height: 1, color: Colors.white.withValues(alpha: 0.05)),
                  itemBuilder: (_, i) {
                    // Clear option at top
                    if (i == 0) {
                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        title: Text(
                          'Clear',
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            color: _kSlate400,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        onTap: () => Navigator.pop(ctx, ''),
                      );
                    }
                    final item = items[i - 1];
                    final isActive = item == current;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Text(
                        item,
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          color: isActive ? _kPrimary : Colors.white,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                      trailing: isActive
                          ? const Icon(Icons.check_rounded,
                              color: _kPrimary, size: 20)
                          : null,
                      onTap: () => Navigator.pop(ctx, item),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Item Card ───────────────────────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

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
      return jsonDecode(utf8.decode(base64Url.decode(padded)))
          as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _openChat(BuildContext context) async {
    final token = await StorageService().getToken();
    if (token == null) return;

    final payload = _decodeJwtPayload(token);
    final currentUserId = (payload['sub'] as String?) ?? '';

    final itemId   = item['id']?.toString() ?? '';
    final finderId = item['user_id']?.toString() ?? '';

    final chatId =
        await ChatController().startChat(itemId, finderId, currentUserId);
    if (chatId == null) return;
    // The initiator is opening the chat themselves — mark it seen so they
    // don't see a blue "NEW" sign on their own conversation.
    await BadgeService.saveSeenChatId(chatId);
    if (!context.mounted) return;

    final features = item['features'];
    final itemName =
        (features is Map ? features['description'] as String? : null) ??
            (item['name'] as String?) ??
            'Unknown Item';
    final district = (item['district'] as String?) ?? '';
    final foundDate = (item['created_at'] as String?) ?? '';

    final itemPhoto = jsonEncode(_buildPhotoUrls());
    final itemCategory = item['category']?.toString() ?? '';
    final itemFeatures =
        (item['features'] is Map<String, dynamic>)
            ? item['features'] as Map<String, dynamic>
            : <String, dynamic>{};

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          itemName: itemName,
          district: district,
          foundDate: foundDate,
          finderId: finderId,
          itemPhoto: itemPhoto,
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
                child: const Row(children: []),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

