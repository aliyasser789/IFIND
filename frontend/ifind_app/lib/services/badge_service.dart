import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Two independent trackers:
///
/// 1. **Seen chat IDs** — a set of chats the user has ever opened. Drives
///    the blue "NEW" pill in the chat list (per user, once only).
///
/// 2. **Seen message count** — per chat, the message count at the moment
///    the user last saw that conversation. Drives the red dot on the
///    nav-bar chat icon (per message, WhatsApp-style — every unseen
///    message bumps the counter).
class BadgeService {
  static const _seenChatIdsKey = 'seen_chat_ids';
  static const _seenMessageCountsKey = 'seen_message_counts';

  /// Live counter the nav bar listens to (per-message unread).
  static final ValueNotifier<int> badgeCount = ValueNotifier<int>(0);

  // ── Per-user seen-chat tracking (drives blue NEW pill) ─────────────────────

  static Future<void> saveSeenChatId(String chatId) async {
    if (chatId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_seenChatIdsKey) ?? '';
    final ids = existing.isEmpty ? <String>{} : existing.split(',').toSet();
    if (ids.add(chatId)) {
      await prefs.setString(_seenChatIdsKey, ids.join(','));
    }
  }

  static Future<Set<String>> getSeenChatIds() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_seenChatIdsKey) ?? '';
    if (stored.isEmpty) return <String>{};
    return stored.split(',').toSet();
  }

  /// Count of chats the user has never opened (for the list's blue NEW pill).
  static Future<int> getUnseenChatCount(
      List<Map<String, dynamic>> chats) async {
    if (chats.isEmpty) return 0;
    final seen = await getSeenChatIds();
    var count = 0;
    for (final chat in chats) {
      final id = (chat['chat_id'] ?? chat['id'])?.toString() ?? '';
      if (id.isNotEmpty && !seen.contains(id)) count++;
    }
    return count;
  }

  // ── Per-message seen-count tracking (drives nav-bar red dot) ───────────────

  static Future<Map<String, int>> _readSeenCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_seenMessageCountsKey);
    if (raw == null || raw.isEmpty) return <String, int>{};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  static Future<void> saveSeenCount(String chatId, int count) async {
    if (chatId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final map = await _readSeenCounts();
    map[chatId] = count;
    await prefs.setString(_seenMessageCountsKey, jsonEncode(map));
  }

  static Future<int> getSeenCount(String chatId) async {
    if (chatId.isEmpty) return 0;
    final map = await _readSeenCounts();
    return map[chatId] ?? 0;
  }

  /// Sum of unseen messages across all chats — drives the red nav-bar dot.
  static Future<int> getUnreadMessageCount(
      List<Map<String, dynamic>> chats) async {
    if (chats.isEmpty) return 0;
    final seenCounts = await _readSeenCounts();
    var total = 0;
    for (final chat in chats) {
      final id = (chat['chat_id'] ?? chat['id'])?.toString() ?? '';
      if (id.isEmpty) continue;
      final current = (chat['message_count'] as int?) ?? 0;
      final seen = seenCounts[id] ?? 0;
      final delta = current - seen;
      if (delta > 0) total += delta;
    }
    return total;
  }
}
