import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

// Base URL is injected at build time via --dart-define=BASE_URL=...
// Default (no flag) = Android emulator → host machine localhost.
// Use the VS Code launch configs in .vscode/launch.json to switch easily.
const String _baseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'http://192.168.1.2:8000',
);

class WebSocketService {
  WebSocketChannel? _channel;

  /// Derives the WebSocket base URL from the HTTP base URL.
  String get _wsBaseUrl => _baseUrl.replaceFirst('http://', 'ws://');

  /// Opens a WebSocket connection to /chat/ws/{chatId}?sender_id={senderId}.
  void connect(String chatId, String senderId) {
    final uri = Uri.parse('$_wsBaseUrl/chat/ws/$chatId?sender_id=$senderId');
    _channel = WebSocketChannel.connect(uri);
  }

  /// A [Stream] that emits decoded JSON messages as they arrive from the server.
  Stream<Map<String, dynamic>> get onMessage {
    return _channel!.stream.map((raw) {
      final decoded = jsonDecode(raw as String);
      return decoded as Map<String, dynamic>;
    });
  }

  /// Sends a text message through the open WebSocket connection.
  void sendMessage(String content) {
    _channel!.sink.add(content);
  }

  /// Closes the WebSocket connection cleanly.
  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
  }
}
