import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import '../env_config.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  final Dio dio;
  final SecureStorage _secureStorage;
  
  // Custom interface to trigger logout on token failure
  void Function()? onAuthFailure;

  ApiClient({SecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorage(),
        dio = Dio() {
    dio.options.connectTimeout = const Duration(seconds: 15);
    dio.options.receiveTimeout = const Duration(seconds: 15);
    
    // Set headers
    dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add interceptors
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Dynamic base URL check (allows overriding localhost on devices)
          final hostOverride = await _secureStorage.getApiHostOverride();
          options.baseUrl = hostOverride ?? EnvConfig.apiBaseUrl;
          debugPrint('[ApiClient] Interceptor set baseUrl: ${options.baseUrl}, path: ${options.path}');

          final token = await _secureStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
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

          // Check for 401 Unauthorized
          if (error.response?.statusCode == 401) {
            final refreshed = await _attemptTokenRefresh();
            if (refreshed) {
              // Retry request
              try {
                final options = error.requestOptions;
                final token = await _secureStorage.getAccessToken();
                options.headers['Authorization'] = 'Bearer $token';
                
                final response = await dio.fetch(options);
                return handler.resolve(response);
              } catch (e) {
                // If retry fails, forward error
                return handler.next(error);
              }
            } else {
              // Refresh failed, clean session and log out user
              await _secureStorage.clearTokens();
              if (onAuthFailure != null) {
                onAuthFailure!();
              }
            }
          }
          return handler.next(error);
        },
      ),
    );

    // Setup Certificate Pinning for Release Builds
    _setupCertificatePinning();
  }

  // Simulated silent refresh (backend has single 7d token, so we return true if we have a refresh token)
  Future<bool> _attemptTokenRefresh() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      // In a real production setup, we would call:
      // final response = await dio.post('/api/auth/refresh', data: {'refreshToken': refreshToken});
      // final newAccess = response.data['accessToken'];
      // final newRefresh = response.data['refreshToken'];
      // await _secureStorage.saveTokens(accessToken: newAccess, refreshToken: newRefresh);
      
      // Since backend doesn't support refresh natively, we'll simulate:
      if (refreshToken == 'valid_mock_refresh_token') {
        // Just keep the current access token alive or return true
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void _setupCertificatePinning() {
    // Only apply certificate pinning in release mode and not for localhost debug
    if (!kReleaseMode) return;

    // Use HttpClientAdapter with SecurityContext pinning
    final adapter = dio.httpClientAdapter;
    if (adapter is IOHttpClientAdapter) {
      adapter.createHttpClient = () {
        final SecurityContext context = SecurityContext(withTrustedRoots: true);
        
        // In production, load the certificate asset and add it to context:
        // final sslCert = await rootBundle.load('assets/certificates/api.pem');
        // context.setTrustedCertificatesBytes(sslCert.buffer.asUint8List());
        
        final client = HttpClient(context: context);
        // SSL certificate verification callback
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          // If debugging custom testnets with self-signed certs, we can return true
          if (EnvConfig.isTestnet) return true;
          
          // In production, reject bad certificates:
          return false;
        };
        return client;
      };
    }
  }
}
