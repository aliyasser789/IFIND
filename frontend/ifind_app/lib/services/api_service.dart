import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ifind_app/services/storage_service.dart';

// Base URL is injected at build time via --dart-define=BASE_URL=...
// Default (no flag) = Android emulator → host machine localhost.
// Use the VS Code launch configs in .vscode/launch.json to switch easily.
const String baseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 60),
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
  /// Returns {success: bool, access_token: String?, id_verified: bool?, message: String}
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
      return {
        'success': true,
        'access_token': data['access_token'],
        'id_verified': data['id_verified'],
      };
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;
        final detail =
            (data is Map) ? (data['detail'] ?? 'Login failed') : 'Login failed';
        return {'success': false, 'message': detail.toString()};
      }
      return {
        'success': false,
        'message': 'Cannot connect to server. Is the backend running?',
      };
    }
  }

  /// POST /auth/forgot-password
  /// Returns {success: bool, message: String}
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
      final data = response.data as Map<String, dynamic>;
      final message = data['message'] as String? ?? 'Code sent.';
      return {'success': true, 'message': message};
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;
        final detail = (data is Map)
            ? (data['detail'] ?? 'Failed to send reset code')
            : 'Failed to send reset code';
        return {'success': false, 'message': detail.toString()};
      }
      return {
        'success': false,
        'message': 'Cannot connect to server. Is the backend running?',
      };
    }
  }

  /// POST /auth/verify-reset-otp
  /// Returns {success: bool, message: String}
  Future<Map<String, dynamic>> verifyResetOtp(
      String email, String otpCode) async {
    try {
      final response = await _dio.post(
        '/auth/verify-reset-otp',
        data: {'email': email, 'otp_code': otpCode},
      );
      final data = response.data as Map<String, dynamic>;
      final message = data['message'] as String? ?? 'OTP verified.';
      return {'success': true, 'message': message};
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;
        final detail = (data is Map)
            ? (data['detail'] ?? 'OTP verification failed')
            : 'OTP verification failed';
        return {'success': false, 'message': detail.toString()};
      }
      return {
        'success': false,
        'message': 'Cannot connect to server. Is the backend running?',
      };
    }
  }

  /// POST /auth/reset-password
  /// Returns {success: bool, message: String}
  Future<Map<String, dynamic>> resetPassword(
      String email, String newPassword, String confirmPassword) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {
          'email': email,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final message = data['message'] as String? ?? 'Password reset.';
      return {'success': true, 'message': message};
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;
        final detail = (data is Map)
            ? (data['detail'] ?? 'Password reset failed')
            : 'Password reset failed';
        return {'success': false, 'message': detail.toString()};
      }
      return {
        'success': false,
        'message': 'Cannot connect to server. Is the backend running?',
      };
    }
  }

  /// GET /items/districts
  /// Returns a list of district strings, or empty list on failure.
  Future<List<String>> getDistricts() async {
    final token = await StorageService().getToken();
    if (token == null) return [];
    try {
      final response = await _dio.get(
        '/items/districts',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final raw = response.data;
      final data = (raw is String ? jsonDecode(raw) : raw) as List<dynamic>;
      return data.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  /// GET /items/categories
  /// Returns a list of category strings, or empty list on failure.
  Future<List<String>> getCategories() async {
    final token = await StorageService().getToken();
    if (token == null) return [];
    try {
      final response = await _dio.get(
        '/items/categories',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final raw = response.data;
      final data = (raw is String ? jsonDecode(raw) : raw) as List<dynamic>;
      return data.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  /// GET /items/recent
  /// Returns a list of the most recently found items, or empty list on failure.
  Future<List<Map<String, dynamic>>> getRecentItems() async {
    final token = await StorageService().getToken();
    if (token == null) return [];
    try {
      final response = await _dio.get(
        '/items/recent',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final raw = response.data;
      final data = (raw is String ? jsonDecode(raw) : raw) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// GET /items/search?keywords=X&district=Y&category=Z
  /// All query params are optional. Returns matching items, or empty list on failure.
  Future<List<Map<String, dynamic>>> searchItems({
    String? keywords,
    String? district,
    String? category,
  }) async {
    final token = await StorageService().getToken();
    if (token == null) return [];
    try {
      final queryParams = <String, String>{};
      if (keywords != null) queryParams['keywords'] = keywords;
      if (district != null) queryParams['district'] = district;
      if (category != null) queryParams['category'] = category;

      final response = await _dio.get(
        '/items/search',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final raw = response.data;
      final data = (raw is String ? jsonDecode(raw) : raw) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// GET /user/me
  /// Returns the authenticated user's username, or null on failure.
  Future<String?> getMe() async {
    final token = await StorageService().getToken();
    if (token == null) return null;
    try {
      final response = await _dio.get(
        '/user/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final raw = response.data;
      final data =
          (raw is String ? jsonDecode(raw) : raw) as Map<String, dynamic>;
      return data['username'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// POST /reports/submit
  /// Returns true on success, throws DioException on failure.
  Future<bool> submitReport({
    required String chatId,
    required String reportedId,
    required List<String> reasons,
    String? description,
  }) async {
    final token = await StorageService().getToken();
    if (token == null) throw Exception('Not authenticated');
    final body = <String, dynamic>{
      'chat_id': chatId,
      'reported_id': reportedId,
      'reasons': reasons,
    };
    if (description != null) body['description'] = description;
    final response = await _dio.post(
      '/reports/submit',
      data: body,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.statusCode == 201;
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
