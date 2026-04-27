import 'dart:async';

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
  Map<String, int> _unreadByChat = <String, int>{};
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadChats();
    // Poll every 5 seconds so per-row unread counts stay fresh while the user
    // is looking at the list. main_shell polls the nav-bar total separately;
    // this one updates the per-chat red pills.
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadChats(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadChats() async {
    final chats = await _chatController.getUserChats();
    final seenIds = await BadgeService.getSeenChatIds();

    // Per-chat unread counts so each row can show "user X has N new messages".
    final unreadByChat = <String, int>{};
    var totalUnread = 0;
    for (final chat in chats) {
      final id = (chat['chat_id'] ?? chat['id'])?.toString() ?? '';
      if (id.isEmpty) continue;
      final current = (chat['message_count'] as int?) ?? 0;
      final seen = await BadgeService.getSeenCount(id);
      final delta = current - seen;
      if (delta > 0) {
        unreadByChat[id] = delta;
        totalUnread += delta;
      }
    }

    if (mounted) {
      BadgeService.badgeCount.value = totalUnread;
      setState(() {
        _chats = chats;
        _isLoading = false;
        _seenIds = seenIds;
        _unreadByChat = unreadByChat;
      });
    }
  }

  Future<void> _openChat(Map<String, dynamic> chat) async {
    final chatId = (chat['chat_id'] ?? chat['id'])?.toString() ?? '';
    final itemName = (chat['item_name'] as String?) ?? 'Unknown Item';
    final district = (chat['district'] as String?) ?? '';
    final foundDate = (chat['foundDate'] as String?) ?? '';
    final finderId = (chat['finder_id'] ?? 0).toString();
    final otherUsername = (chat['other_user_username'] as String?) ?? 'Unknown User';

    // Build full photo URL the same way _ChatRow does
    final itemId = chat['item_id']?.toString() ?? '';
    final photoFile = (chat['item_photo_url'] as String?) ?? '';
    final photoFilename = photoFile.split('/').last;
    final itemPhoto = (photoFilename.isNotEmpty && itemId.isNotEmpty)
        ? '$_kBaseUrl/items/photos/$itemId/$photoFilename'
        : '';
    final itemCategory = (chat['item_category'] as String?) ?? '';

    // Mark the chat seen the moment the user opens it (WhatsApp-style) so
    // both the blue NEW pill (per-user) and the red nav-bar counter
    // (per-message) clear instantly.
    if (chatId.isNotEmpty) {
      final msgCount = (chat['message_count'] as int?) ?? 0;
      await BadgeService.saveSeenChatId(chatId);
      await BadgeService.saveSeenCount(chatId, msgCount);
      if (mounted) {
        setState(() => _seenIds = {..._seenIds, chatId});
        BadgeService.badgeCount.value =
            await BadgeService.getUnreadMessageCount(_chats);
      }
    }

    if (!mounted) return;
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
          otherUsername: otherUsername,
        ),
      ),
    );
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
                              unreadCount: _unreadByChat[chatId] ?? 0,
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
  const _ChatRow({
    required this.chat,
    required this.onTap,
    required this.isNew,
    required this.unreadCount,
  });

  final Map<String, dynamic> chat;
  final VoidCallback onTap;
  final bool isNew;
  final int unreadCount;

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
    final district = (chat['district'] as String?) ?? '';
    final otherLabel = (chat['other_user_username'] as String?) ?? 'Unknown User';
    final rawDate = chat['created_at']?.toString() ?? '';
    final parsedDate = DateTime.tryParse(rawDate);
    final dateLabel = parsedDate != null
        ? '${parsedDate.month}/${parsedDate.day}/${parsedDate.year}'
        : rawDate;
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
                      // other_user_username
                      Text(
                        otherLabel,
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // District · date
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
                              dateLabel,
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

                // ── Per-user unread-message count ──────────────────────
                if (unreadCount > 0) ...[
                  Container(
                    constraints: const BoxConstraints(minWidth: 22),
                    height: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE24B4A),
                      borderRadius: BorderRadius.all(Radius.circular(11)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                // ── Chevron ───────────────────────────────────────────
                const Icon(Icons.chevron_right, color: _kHint, size: 20),
              ],
            ),
          ),

          // ── Blue NEW badge — only for chats the user hasn't opened yet ──
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
