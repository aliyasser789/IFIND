import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/chat_controller.dart';
import '../services/badge_service.dart';
import 'chat_screen.dart';

// ── Base URL (injected at build time via --dart-define=BASE_URL=...) ─────────
const _kBaseUrl = String.fromEnvironment('BASE_URL', defaultValue: '');

// ── Design tokens ────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF135BEC);
const _kAccentPurple = Color(0xFF8B5CF6);
const _kBackground = Color(0xFF101622);
const _kTopBar = Color(0xFF13192A);
const _kBorder = Color(0xFF1E2438);
const _kHint = Color(0xFF6B7280);
const _kSlate400 = Color(0xFF94A3B8);

// ─────────────────────────────────────────────────────────────────────────────
// ChatListScreen — Chat tab body, rendered inside MainShell's IndexedStack
// ─────────────────────────────────────────────────────────────────────────────
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _chatController = ChatController();
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;
  Set<String> _seenIds = {};

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final chats = await _chatController.getUserChats();
    chats.sort((a, b) {
      final aDate =
          DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(0);
      final bDate =
          DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(0);
      return bDate.compareTo(aDate);
    });
    final seenIds = await BadgeService.getSeenChatIds();
    if (mounted) {
      setState(() {
        _chats = chats;
        _isLoading = false;
        _seenIds = seenIds;
      });
    }
  }

  Future<void> _openChat(Map<String, dynamic> chat) async {
    final chatId = (chat['chat_id'] ?? chat['id'])?.toString() ?? '';
    final itemName = (chat['item_name'] as String?) ?? 'Unknown Item';
    final district = (chat['district'] as String?) ?? '';
    final foundDate = (chat['found_date'] as String?) ?? '';
    final finderId = (chat['finder_id'] ?? 0).toString();

    // Build full photo URL the same way _ChatRow does
    final itemId = chat['item_id']?.toString() ?? '';
    final photoFile = (chat['item_photo_url'] as String?) ?? '';
    final photoFilename = photoFile.split('/').last;
    final itemPhoto = (photoFilename.isNotEmpty && itemId.isNotEmpty)
        ? '$_kBaseUrl/items/photos/$itemId/$photoFilename'
        : '';
    final itemCategory = (chat['item_category'] as String?) ?? '';

    await Navigator.push(
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
          itemFeatures: (chat['item_features'] as Map<String, dynamic>?) ?? {},
        ),
      ),
    );
    if (chatId.isNotEmpty) {
      await BadgeService.saveSeenChatId(chatId);
    }
    await _loadChats();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            color: _kHint,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            'No chats yet',
            style: GoogleFonts.manrope(
              color: _kHint,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your conversations will appear here',
            style: GoogleFonts.manrope(
              color: _kHint,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: Column(
        children: [
          // ── Top bar ──────────────────────────────────────────────────
          const _ChatListTopBar(),

          // ── Body ─────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _kPrimary),
                  )
                : _chats.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        itemCount: _chats.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final chat = _chats[i];
                          final chatId =
                              (chat['chat_id'] ?? chat['id'])?.toString() ?? '';
                          return Dismissible(
                            key: ValueKey(
                                chatId.isNotEmpty ? chatId : i.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE24B4A),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            onDismissed: (_) async {
                              setState(() => _chats.removeAt(i));
                              await _chatController.deleteChat(chatId);
                              if (chatId.isNotEmpty) {
                                await BadgeService.saveSeenChatId(chatId);
                              }
                              await _loadChats();
                            },
                            child: _ChatRow(
                              chat: chat,
                              onTap: () => _openChat(chat),
                              isNew: !_seenIds.contains(chatId),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Top Bar ─────────────────────────────────────────────────────────────────
class _ChatListTopBar extends StatelessWidget {
  const _ChatListTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kTopBar,
        border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'My Chats',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Chat Row ────────────────────────────────────────────────────────────────
class _ChatRow extends StatelessWidget {
  const _ChatRow(
      {required this.chat, required this.onTap, required this.isNew});

  final Map<String, dynamic> chat;
  final VoidCallback onTap;
  final bool isNew;

  Widget _photoPlaceholder() => Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: _kBorder,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: const Icon(Icons.image_not_supported_outlined,
            color: _kSlate400, size: 20),
      );

  @override
  Widget build(BuildContext context) {
    final itemName = (chat['item_name'] as String?) ?? 'Unknown Item';
    final district = (chat['district'] as String?) ?? '';
    final otherLabel = (chat['other_user_label'] as String?) ??
        (chat['other_label'] as String?) ??
        'Anonymous';
    final itemId = chat['item_id']?.toString() ?? '';
    final photoFile = chat['item_photo_url'] as String?;
    final photoFilename = photoFile?.split('/').last ?? '';
    final photoUrl = (photoFilename.isNotEmpty && itemId.isNotEmpty)
        ? '$_kBaseUrl/items/photos/$itemId/$photoFilename'
        : null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Card ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _kTopBar,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder, width: 1),
            ),
            child: Row(
              children: [
                // ── Item photo thumbnail ───────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: photoUrl != null
                      ? Image.network(
                          photoUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _photoPlaceholder(),
                        )
                      : _photoPlaceholder(),
                ),
                const SizedBox(width: 14),

                // ── Text column ───────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item name
                      Text(
                        itemName,
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // District + other user label on same row
                      Row(
                        children: [
                          if (district.isNotEmpty) ...[
                            Text(
                              district,
                              style: GoogleFonts.manrope(
                                color: _kAccentPurple,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: _kHint,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              otherLabel,
                              style: GoogleFonts.manrope(
                                color: _kHint,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Chevron ───────────────────────────────────────────
                const Icon(Icons.chevron_right, color: _kHint, size: 20),
              ],
            ),
          ),

          // ── NEW badge ─────────────────────────────────────────────────
          if (isNew)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'NEW',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
