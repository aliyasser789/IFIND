import 'package:shared_preferences/shared_preferences.dart';

class BadgeService {
  static const _seenChatIdsKey = 'seen_chat_ids';

  /// Adds [chatId] to the persisted set of seen chat IDs.
  static Future<void> saveSeenChatId(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_seenChatIdsKey) ?? '';
    final ids = existing.isEmpty
        ? <String>{}
        : existing.split(',').toSet();
    ids.add(chatId);
    await prefs.setString(_seenChatIdsKey, ids.join(','));
  }

  /// Returns the full set of chat IDs the user has already opened.
  static Future<Set<String>> getSeenChatIds() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_seenChatIdsKey) ?? '';
    if (stored.isEmpty) return {};
    return stored.split(',').toSet();
  }

  /// Returns how many IDs in [allChatIds] are NOT in the seen set.
  static Future<int> getUnseenCount(List<String> allChatIds) async {
    final seen = await getSeenChatIds();
    return allChatIds.where((id) => !seen.contains(id)).length;
  }
}
