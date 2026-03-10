import 'package:dio/dio.dart';

const String baseUrl = "http://localhost:8000";

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));

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
}
