import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kMyBubble = Color(0xFF135BEC);
const _kOtherBubble = Color(0xFF2A2A3D);
const _kMeta = Color(0xFF6B7280);

// ─── ChatBubble ───────────────────────────────────────────────────────────────
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.content,
    required this.senderLabel,
    required this.sentAt,
    required this.isMe,
  });

  final String content;
  final String senderLabel;
  final String sentAt;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.75;

    // WhatsApp-style: flatten the corner closest to the chat edge.
    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 18),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // ── Bubble ────────────────────────────────────────────────────────
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: isMe ? _kMyBubble : _kOtherBubble,
                borderRadius: bubbleRadius,
              ),
              child: Text(
                content,
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ),

          // ── Meta row: senderLabel · sentAt ────────────────────────────────
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Text(
              '$senderLabel · $sentAt',
              textAlign: isMe ? TextAlign.right : TextAlign.left,
              style: GoogleFonts.manrope(
                color: _kMeta,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
