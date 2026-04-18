import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:ifind_app/services/api_service.dart';
import 'package:ifind_app/services/storage_service.dart';

class ChatController {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    contentType: 'application/json',
  ));

  /// POST /chat/start
  /// Returns the chat_id as a String, or null on failure.
  Future<String?> startChat(String itemId, String finderId, String claimerId) async {
    if (itemId.isEmpty || finderId.isEmpty || claimerId.isEmpty) return null;
    final token = await StorageService().getToken();
    if (token == null) return null;
    try {
      final response = await _dio.post(
        '/chat/start',
        data: jsonEncode({
          'item_id': itemId,
          'finder_id': finderId,
          'claimer_id': claimerId,
        }),
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        }),
      );
      final raw = response.data;
      final data =
          (raw is String ? jsonDecode(raw) : raw) as Map<String, dynamic>;
      return data['chat_id']?.toString();
    } catch (e) {
      return null;
    }
  }

  /// GET /chat/history/{chatId}
  /// Returns a list of message maps, or empty list on failure.
  Future<List<Map<String, dynamic>>> getChatHistory(String chatId) async {
    final token = await StorageService().getToken();
    if (token == null) return [];
    try {
      final response = await _dio.get(
        '/chat/history/$chatId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final raw = response.data;
      final data = (raw is String ? jsonDecode(raw) : raw) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// DELETE /chat/{chatId}
  /// Deletes the chat and its messages. Returns true on success.
  Future<bool> deleteChat(String chatId) async {
    if (chatId.isEmpty) return false;
    final token = await StorageService().getToken();
    if (token == null) return false;
    try {
      await _dio.delete(
        '/chat/$chatId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// GET /chat/list
  /// Returns a list of chat maps for the authenticated user, or empty list on failure.
  Future<List<Map<String, dynamic>>> getUserChats() async {
    final token = await StorageService().getToken();
    if (token == null) return [];
    try {
      final response = await _dio.get(
        '/chat/list',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final raw = response.data;
      final data = (raw is String ? jsonDecode(raw) : raw) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }
}
