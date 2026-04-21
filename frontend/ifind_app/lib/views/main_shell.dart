import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/chat_controller.dart';
import '../services/badge_service.dart';
import 'chat_list_screen.dart';
import 'found_screen.dart';
import 'home_screen.dart';
import 'lost_screen.dart';
import 'settings_screen.dart';

// ── Design tokens (identical to home_screen.dart palette) ────────────────────
const _kPrimary = Color(0xFF135BEC);
const _kSlate400 = Color(0xFF94A3B8);
const _kSlate900 = Color(0xFF0F172A);

// ─────────────────────────────────────────────────────────────────────────────
// MainShell — persistent bottom nav host for Home / Chat / Settings
// ─────────────────────────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _unreadCount = 0;
  Timer? _badgeTimer;

  @override
  void initState() {
    super.initState();
    _unreadCount = BadgeService.badgeCount.value;
    BadgeService.badgeCount.addListener(_onBadgeChanged);
    _refreshBadge();
    _badgeTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshBadge(),
    );
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    BadgeService.badgeCount.removeListener(_onBadgeChanged);
    super.dispose();
  }

  void _onBadgeChanged() {
    if (mounted) setState(() => _unreadCount = BadgeService.badgeCount.value);
  }

  /// Fetches the current unread-message count (summed across all chats)
  /// for the Chat tab badge. Polled every 5s, WhatsApp-style.
  Future<void> _refreshBadge() async {
    final chats = await ChatController().getUserChats();
    if (!mounted) return;
    final unread = await BadgeService.getUnreadMessageCount(chats);
    if (!mounted) return;
    BadgeService.badgeCount.value = unread;
  }

  void _onTabTap(int index) {
    _refreshBadge();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps all 5 screens alive — no rebuild on tab switch.
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(onTabSwitch: _onTabTap),
          const LostScreen(),
          FoundScreen(onSubmitSuccess: () => _onTabTap(0)),
          const ChatListScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _ShellNavBar(
        currentIndex: _currentIndex,
        unreadCount: _unreadCount,
        onTap: _onTabTap,
      ),
    );
  }
}

// ─── Persistent Shell Nav Bar ─────────────────────────────────────────────────
class _ShellNavBar extends StatelessWidget {
  const _ShellNavBar({
    required this.currentIndex,
    required this.unreadCount,
    required this.onTap,
  });

  final int currentIndex;
  final int unreadCount;
  final ValueChanged<int> onTap;

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
                    icon: Icons.home_rounded,
                    label: 'HOME',
                    isActive: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _NavItem(
                    icon: Icons.search_rounded,
                    label: 'I LOST',
                    isActive: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  _NavItem(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'I FOUND',
                    isActive: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                  _NavItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'CHAT',
                    isActive: currentIndex == 3,
                    onTap: () => onTap(3),
                    unreadCount: unreadCount,
                  ),
                  _NavItem(
                    icon: Icons.settings_rounded,
                    label: 'SETTINGS',
                    isActive: currentIndex == 4,
                    onTap: () => onTap(4),
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

// ─── Nav Item ─────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.onTap,
    this.unreadCount = 0,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;
  final int unreadCount;

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
            // Badge overlay when there are unseen messages.
            unreadCount > 0
                ? Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(icon, color: color, size: 24),
                      Positioned(
                        top: -4,
                        right: -6,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE24B4A),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Icon(icon, color: color, size: 24),
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
