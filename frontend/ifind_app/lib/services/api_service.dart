import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ifind_app/services/storage_service.dart';

// 10.0.2.2 maps to the host machine's localhost when running on Android emulator.
// For a physical device, replace with your machine's LAN IP (e.g. http://192.168.1.x:8000).
const String baseUrl = "http://192.168.100.194:8000";

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  Future<bool> pingServer() async {
    try {
      print('Pinging $baseUrl/ping ...');
      final response = await _dio.get('/ping');
      print('Ping response: ${response.statusCode} ${response.data}');
      return response.statusCode == 200;
    } catch (e) {
      print('Ping failed: type=${e.runtimeType} message=$e');
      if (e is DioException) {
        print('DioException type: ${e.type}');
        print('DioException message: ${e.message}');
      }
      return false;
    }
  }

  /// POST /auth/send-verification
  /// Returns {success: bool, message: String}
  Future<Map<String, dynamic>> sendVerificationCode({
    required String email,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/send-verification',
        data: {'email': email},
      );
      final message =
          (response.data as Map<String, dynamic>)['message'] as String? ??
              'Code sent.';
      return {'success': true, 'message': message};
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;
        final detail = (data is Map)
            ? (data['detail'] ?? 'Failed to send code')
            : 'Failed to send code';
        return {'success': false, 'message': detail.toString()};
      }
      return {
        'success': false,
        'message': 'Cannot connect to server. Is the backend running?',
      };
    }
  }

  /// POST /auth/verify-email
  /// Returns {success: bool, message: String} — no token at this stage.
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/verify-email',
        data: {'email': email, 'code': code},
      );
      final data = response.data as Map<String, dynamic>;
      final message = data['message'] as String? ?? 'Email verified.';
      return {'success': true, 'message': message};
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;
        final detail = (data is Map)
            ? (data['detail'] ?? 'Verification failed')
            : 'Verification failed';
        return {'success': false, 'message': detail.toString()};
      }
      return {
        'success': false,
        'message': 'Cannot connect to server. Is the backend running?',
      };
    }
  }

  /// POST /auth/verify-id
  /// Sends the user's email and front-of-ID image as multipart — no JWT required.
  /// On success the backend returns the JWT token for the first time.
  /// Returns {success: bool, verified: bool, access_token: String?, ...fields or error: String}
  Future<Map<String, dynamic>> verifyId({
    required String email,
    required File imageFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'email': email,
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'id_front.jpg',
        ),
      });
      final response = await _dio.post(
        '/auth/verify-id',
        data: formData,
      );
      final data = response.data as Map<String, dynamic>;
      return {'success': true, ...data};
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;
        final detail = (data is Map)
            ? (data['detail'] ?? 'Verification failed')
            : 'Verification failed';
        return {'success': false, 'error': detail.toString()};
      }
      return {
        'success': false,
        'error': 'Cannot connect to server. Is the backend running?'
      };
    }
  }

  /// POST /auth/upload-id-back
  /// Sends back-of-ID image as multipart with Bearer JWT.
  /// Returns {success: bool, message: String}
  Future<Map<String, dynamic>> uploadIdBack({required File imageFile}) async {
    final token = await StorageService().getToken();
    if (token == null) {
      return {
        'success': false,
        'error': 'Not authenticated. Please log in again.'
      };
    }
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'id_back.jpg',
        ),
      });
      final response = await _dio.post(
        '/auth/upload-id-back',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data as Map<String, dynamic>;
      return {'success': true, ...data};
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;
        final detail = (data is Map)
            ? (data['detail'] ?? 'Upload failed')
            : 'Upload failed';
        return {'success': false, 'error': detail.toString()};
      }
      return {
        'success': false,
        'error': 'Cannot connect to server. Is the backend running?'
      };
    }
  }

  /// POST /auth/login
  /// Returns {success: bool, access_token: String?, message: String}
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      return {'success': true, 'access_token': data['access_token']};
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;
        final detail = (data is Map)
            ? (data['detail'] ?? 'Login failed')
            : 'Login failed';
        return {'success': false, 'message': detail.toString()};
      }
      return {
        'success': false,
        'message': 'Cannot connect to server. Is the backend running?',
      };
    }
  }

  /// POST /auth/register
  /// Returns {success: bool, message: String}
  Future<Map<String, dynamic>> register({
    required String fullName,
    required int age,
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'full_name': fullName,
          'age': age,
          'email': email,
          'username': username,
          'password': password,
          'confirm_password': confirmPassword,
        },
      );
      final message =
          (response.data as Map<String, dynamic>)['message'] as String? ??
              'Account created.';
      return {'success': true, 'message': message};
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;
        final detail = (data is Map)
            ? (data['detail'] ?? 'Registration failed')
            : 'Registration failed';
        return {'success': false, 'message': detail.toString()};
      }
      return {
        'success': false,
        'message': 'Cannot connect to server. Is the backend running?',
      };
    }
  }
}
