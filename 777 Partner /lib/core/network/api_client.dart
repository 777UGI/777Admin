import "package:dio/dio.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../env_config.dart";
import "../storage/secure_storage.dart";

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  
  final dio = Dio(BaseOptions(
    baseUrl: EnvConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      "Content-Type": "application/json",
      "Accept": "application/json",
    },
  ));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final override = await storage.getHostOverride();
        if (override != null && override.isNotEmpty) {
          options.baseUrl = "http://$override/api";
        }
        
        final token = await storage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers["Authorization"] = "Bearer $token";
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        // Automatic LAN fallback if USB localhost is unreachable
        if ((error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.connectionError) &&
            error.requestOptions.baseUrl == EnvConfig.apiBaseUrl &&
            error.requestOptions.extra['retried_lan'] != true) {
          try {
            final newOptions = error.requestOptions;
            newOptions.baseUrl = EnvConfig.lanBaseUrl;
            newOptions.extra['retried_lan'] = true;
            final response = await dio.fetch(newOptions);
            return handler.resolve(response);
          } catch (_) {}
        }

        if (error.response?.statusCode == 401) {
          await storage.clearSession();
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
});
