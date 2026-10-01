import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiClient {
  late final Dio dio;
  static Function()? onUnauthorized;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          if (error.response?.statusCode == 401) {
            if (onUnauthorized != null) {
              onUnauthorized!();
            }
          }

          String errorMessage = "An unexpected error occurred.";
          if (error.response != null && error.response?.data != null) {
            final data = error.response?.data;
            if (data is Map && data.containsKey('detail')) {
              errorMessage = data['detail'].toString();
            } else if (data is String) {
              errorMessage = data;
            }
          } else {
            errorMessage = error.message ?? "Connection timeout or server unreachable.";
          }
          return handler.next(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: errorMessage,
            ),
          );
        },
      ),
    );
  }
}
