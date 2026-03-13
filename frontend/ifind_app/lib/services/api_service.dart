import 'package:dio/dio.dart';

// 10.0.2.2 maps to the host machine's localhost when running on Android emulator.
// For a physical device, replace with your machine's LAN IP (e.g. http://192.168.1.x:8000).
const String baseUrl = "http://10.0.2.2:8000";

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
        final data   = e.response!.data;
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
  /// Returns {success: bool, message: String}
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/verify-email',
        data: {'email': email, 'code': code},
      );
      final message =
          (response.data as Map<String, dynamic>)['message'] as String? ??
              'Email verified.';
      return {'success': true, 'message': message};
    } on DioException catch (e) {
      if (e.response != null) {
        final data   = e.response!.data;
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
