import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/chat_controller.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import '../widgets/chat_bubble.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF135BEC);
const _kAccentPurple = Color(0xFF8B5CF6);
const _kBackground = Color(0xFF101622);
const _kTopBar = Color(0xFF13192A);
const _kBorder = Color(0xFF1E2438);
const _kHint = Color(0xFF6B7280);
const _kRed = Color(0xFFE24B4A);
const _kCardBg = Color(0xFF1E2A3A);
const _kSlate400 = Color(0xFF94A3B8);
const _kSlate500 = Color(0xFF64748B);
const _kSlate900 = Color(0xFF0F172A);

// ─────────────────────────────────────────────────────────────────────────────
// ChatScreen
// ─────────────────────────────────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatId,
    required this.itemName,
    required this.district,
    required this.foundDate,
    required this.finderId,
    this.itemPhoto = '',
    this.itemCategory = '',
    this.itemFeatures = const {},
  });

  final String chatId;
  final String itemName;
  final String district;
  final String foundDate;
  final String finderId;
  final String itemPhoto;
  final String itemCategory;
  final Map<String, dynamic> itemFeatures;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatController = ChatController();
  final _wsService = WebSocketService();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  String _currentUserLabel = '';
  String _otherUserLabel = '';
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  // ── Initialise: JWT → history → WebSocket ────────────────────────────────
  Future<void> _init() async {
    // Compute other user label immediately (no async needed)
    _otherUserLabel =
        'User ${widget.finderId.length >= 4 ? widget.finderId.substring(0, 4) : widget.finderId}';

    final token = await StorageService().getToken();
    if (token == null) return;

    final payload = _decodeJwtPayload(token);
    final userId = (payload['sub'] as String?) ?? '';
    // Anonymous label = "User " + first 4 chars of UUID
    _currentUserLabel =
        userId.length >= 4 ? 'User ${userId.substring(0, 4)}' : 'User ';

    // Load history
    final history = await _chatController.getChatHistory(widget.chatId);
    if (!mounted) return;
    setState(() => _messages.addAll(history));
    _scrollToBottom();

    // Open WebSocket
    _wsService.connect(widget.chatId, userId);
    _wsSub = _wsService.onMessage.listen((msg) {
      if (!mounted) return;
      final content = (msg['content'] as String?) ?? '';
      if (content.trim().isEmpty) return;
      setState(() => _messages.add(msg));
      _scrollToBottom();
    });
  }

  // ── JWT payload decoder ──────────────────────────────────────────────────
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

  // ── Auto-scroll ──────────────────────────────────────────────────────────
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Send ─────────────────────────────────────────────────────────────────
  void _sendMessage() {
    final content = _inputController.text.trim();
    if (content.isEmpty) return;
    _wsService.sendMessage(content);
    _inputController.clear();
  }

  // ── Report sheet ─────────────────────────────────────────────────────────
  void _showReportSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _kTopBar,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReportSheet(
        onSubmit: (reasons, description) async {
          try {
            await ApiService().submitReport(
              chatId: widget.chatId,
              reportedId: widget.finderId,
              reasons: reasons,
              description: description,
            );
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Report submitted successfully')),
            );
          } catch (_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to submit report. Please try again.')),
            );
          }
        },
      ),
    );
  }

  // ── Item detail modal ─────────────────────────────────────────────────────
  void _showItemDetailModal() {
    final photoUrl = widget.itemPhoto;
    final category =
        widget.itemCategory.isNotEmpty ? widget.itemCategory : 'Unknown';
    final features = widget.itemFeatures;
    final district = widget.district;
    final dateLabel = _formatFoundDate(widget.foundDate);

    final featureEntries = <MapEntry<String, String>>[];
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
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
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
                            if (district.isNotEmpty)
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
                            if (dateLabel.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                dateLabel,
                                style: GoogleFonts.manrope(
                                  color: _kPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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

  // ── Format found date ────────────────────────────────────────────────────
  String _formatFoundDate(String raw) {
    if (raw.isEmpty) return '';
    try {
      final date = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final itemDay = DateTime(date.year, date.month, date.day);
      final diff = today.difference(itemDay).inDays;
      if (diff == 0) return 'Found Today';
      if (diff == 1) return 'Found Yesterday';
      if (diff < 7) return 'Found $diff days ago';
      return 'Found ${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _wsService.disconnect();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: Column(
        children: [
          _ChatTopBar(
            otherUserLabel: _otherUserLabel,
            district: widget.district,
            foundDate: widget.foundDate,
            onBack: () => Navigator.pop(context),
            onReport: _showReportSheet,
            onTapTitle: _showItemDetailModal,
          ),
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) {
                final msg = _messages[i];
                final senderLabel = (msg['sender_label'] as String?) ?? '';
                final content = (msg['content'] as String?) ?? '';
                final sentAt = (msg['sent_at'] as String?) ?? '';
                return ChatBubble(
                  content: content,
                  senderLabel: senderLabel,
                  sentAt: _formatTime(sentAt),
                  isMe: senderLabel == _currentUserLabel,
                );
              },
            ),
          ),
          _ChatInputBar(
            controller: _inputController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}

// ─── Top Bar ─────────────────────────────────────────────────────────────────
class _ChatTopBar extends StatelessWidget {
  const _ChatTopBar({
    required this.otherUserLabel,
    required this.district,
    required this.foundDate,
    required this.onBack,
    required this.onReport,
    required this.onTapTitle,
  });

  final String otherUserLabel;
  final String district;
  final String foundDate;
  final VoidCallback onBack;
  final VoidCallback onReport;
  final VoidCallback onTapTitle;

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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // ── Back arrow ───────────────────────────────────────────
                GestureDetector(
                  onTap: onBack,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 20),
                  ),
                ),

                // ── Other user label (tappable) + district / date ────────
                Expanded(
                  child: GestureDetector(
                    onTap: onTapTitle,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherUserLabel,
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white.withValues(alpha: 0.35),
                            decorationStyle: TextDecorationStyle.dotted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$district · $foundDate',
                          style: GoogleFonts.manrope(
                            color: _kAccentPurple,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Report button (three dots) ───────────────────────────
                GestureDetector(
                  onTap: onReport,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.more_vert, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Input Bar ───────────────────────────────────────────────────────────────
class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kTopBar,
        border: Border(top: BorderSide(color: _kBorder, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // ── Text field ───────────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _kBorder,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: controller,
                  style: GoogleFonts.manrope(color: Colors.white, fontSize: 14),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: GoogleFonts.manrope(color: _kHint, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // ── Send button ──────────────────────────────────────────────
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: _kPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Report Bottom Sheet ─────────────────────────────────────────────────────
class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.onSubmit});

  final Future<void> Function(List<String>, String?) onSubmit;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  static const _options = [
    'Bullying',
    'Cursing',
    'Threatening',
    'Scamming',
    'Fake Item',
    'Other',
  ];

  final Set<String> _selected = {};
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otherSelected = _selected.contains('Other');
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Report Conversation',
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select all that apply',
            style: GoogleFonts.manrope(color: _kHint, fontSize: 13),
          ),
          const SizedBox(height: 8),

          // Checklist
          ..._options.map((option) {
            return CheckboxListTile(
              value: _selected.contains(option),
              onChanged: (val) => setState(() {
                if (val == true) {
                  _selected.add(option);
                } else {
                  _selected.remove(option);
                  if (option == 'Other') _descriptionController.clear();
                }
              }),
              title: Text(
                option,
                style: GoogleFonts.manrope(color: Colors.white, fontSize: 15),
              ),
              activeColor: _kPrimary,
              checkColor: Colors.white,
              side: const BorderSide(color: _kHint),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            );
          }),

          if (otherSelected) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              style: GoogleFonts.manrope(color: Colors.white, fontSize: 14),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe the issue...',
                hintStyle: GoogleFonts.manrope(color: _kHint, fontSize: 14),
                filled: true,
                fillColor: _kBorder,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () {
                      final desc = otherSelected
                          ? (_descriptionController.text.trim().isEmpty
                              ? null
                              : _descriptionController.text.trim())
                          : null;
                      widget.onSubmit(_selected.toList(), desc);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRed,
                disabledBackgroundColor: _kRed.withValues(alpha: 0.4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Submit Report',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
