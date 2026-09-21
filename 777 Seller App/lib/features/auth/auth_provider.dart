@import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/models/user_model.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';

// Access secure storage provider
final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());

// Access API client provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final client = ApiClient(secureStorage: storage);
  return client;
});

class AuthState {
  final UserModel? user;
  final String? token;
  final bool loading;
  final String? error;
  final bool isOtpSent;
  final String? phoneNumber;
  final bool isRegistered;
  final bool isInitialized;

  AuthState({
    this.user,
    this.token,
    this.loading = false,
    this.error,
    this.isOtpSent = false,
    this.phoneNumber,
    this.isRegistered = false,
    this.isInitialized = false,
  });

  AuthState copyWith({
    UserModel? user,
    String? token,
    bool? loading,
    String? error,
    bool? isOtpSent,
    String? phoneNumber,
    bool? isRegistered,
    bool? isInitialized,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      loading: loading ?? this.loading,
      error: error, // Can reset error by passing null
      isOtpSent: isOtpSent ?? this.isOtpSent,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isRegistered: isRegistered ?? this.isRegistered,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final SecureStorage _secureStorage;

  AuthNotifier(this._apiClient, this._secureStorage) : super(AuthState()) {
    _apiClient.onAuthFailure = logout;
    checkSession();
  }

  Future<void> checkSession() async {
    state = state.copyWith(loading: true);
    try {
      final token = await _secureStorage.getAccessToken();
      final tempPhone = await _secureStorage.getTempPhone();
      if (token != null) {
        // Fast mock session load to avoid network timeout delays
        final mockUser = UserModel(
          id: 'usr-seller-demo',
          name: 'SELLER DEMO',
          email: 'demo@otc.com',
          phone: '+919876543210',
          role: 'seller',
          kycStatus: 'verified',
          createdAt: DateTime.now().toIso8601String(),
        );
        state = AuthState(
          user: mockUser,
          token: token,
          isRegistered: true,
          isInitialized: true,
          phoneNumber: tempPhone,
        );
      } else {
        state = AuthState(isInitialized: true, phoneNumber: tempPhone);
      }
    } catch (e) {
      state = AuthState(isInitialized: true);
    }
  }

  // Step 1: Send OTP to Phone Number (Mocked)
  Future<bool> sendOtp(String phone) async {
    state = state.copyWith(loading: true, error: null);
    try {
      // Simulate API call to send OTP
      await Future.delayed(const Duration(seconds: 1));

      // Check if user already exists (we check if phone is "7777777777" or we check via mock user queries)
      // For this OTA desk app, phone "7777777777" is pre-seeded with email "seller_1784318594941@otc.com"
      final isRegistered = (phone == '7777777777');

      await _secureStorage.saveTempPhone(phone);

      state = state.copyWith(
        loading: false,
        isOtpSent: true,
        phoneNumber: phone,
        isRegistered: isRegistered,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Failed to send OTP. Try again.',
      );
      return false;
    }
  }

  // Step 2: Verify OTP
  Future<bool> verifyOtp(String otp) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(seconds: 1));
      if (otp != '123456') {
        state = state.copyWith(
          loading: false,
          error: 'Invalid 6-digit OTP code.',
        );
        return false;
      }

      if (state.isRegistered && state.phoneNumber == '7777777777') {
        // Auto-login registered seeded user
        return await login('seller_1784318594941@otc.com', '123456');
      }

      // User needs to register or enter details
      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: 'OTP verification failed.');
      return false;
    }
  }

  // Step 3: Register new user
  Future<bool> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final dataMap = <String, dynamic>{
        'name': name,
        'phone': phone.trim(),
        'email': email.toLowerCase().trim(),
        'password': password,
        'role': 'seller',
      };
      if (referralCode != null && referralCode.trim().isNotEmpty) {
        dataMap['referralCode'] = referralCode.trim();
      }
      final response = await _apiClient.dio.post(
        '/api/auth/register',
        data: dataMap,
      );

      if (response.data['success'] == true) {
        final token = response.data['token'] as String;
        final user = UserModel.fromJson(response.data['user']);
        await _secureStorage.saveTokens(
          accessToken: token,
          refreshToken: 'valid_mock_refresh_token',
        );
        await _secureStorage.clearTempPhone();

        state = AuthState(
          user: user,
          token: token,
          isRegistered: true,
          isInitialized: true,
        );
        return true;
      } else {
        state = state.copyWith(
          loading: false,
          error: response.data['error'] ?? 'Registration failed.',
        );
        return false;
      }
    } on DioException catch (e) {
      final message =
          e.response?.data['error'] ?? 'Server error during registration.';
      state = state.copyWith(loading: false, error: message);
      return false;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'An unexpected error occurred.',
      );
      return false;
    }
  }

  // Alternate standard Login (used internally after OTP verify or directly)
  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/login',
        data: {'email': email.toLowerCase().trim(), 'password': password},
      );

      if (response.data['success'] == true) {
        final token = response.data['token'] as String;
        final user = UserModel.fromJson(response.data['user']);
        await _secureStorage.saveTokens(
          accessToken: token,
          refreshToken: 'valid_mock_refresh_token',
        );
        await _secureStorage.clearTempPhone();

        state = AuthState(
          user: user,
          token: token,
          isRegistered: true,
          isInitialized: true,
        );
        return true;
      } else {
        state = state.copyWith(
          loading: false,
          error: response.data['error'] ?? 'Login failed.',
        );
        return false;
      }
    } on DioException catch (e) {
      String message = "Invalid credentials.";
      if (e.response?.data != null && e.response?.data["error"] != null) {
        message = e.response?.data["error"].toString() ?? message;
      } else if (e.response?.statusCode == 404) {
        message = "No account found with this email.";
      } else if (e.response?.statusCode == 401) {
        message = "Incorrect password. Please try again.";
      }
      state = state.copyWith(loading: false, error: message);
      return false;
    } catch (e) {
      state = state.copyWith(loading: false, error: "Connection error: $e");
      return false;
    }
  }

  Future<void> updateKycStatus(String status) async {
    if (state.user != null) {
      state = state.copyWith(user: state.user!.copyWith(kycStatus: status));
    }
  }

  Future<void> logout() async {
    await _secureStorage.clearTokens();
    await _secureStorage.clearTempPhone();
    state = AuthState(isInitialized: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final client = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(client, storage);
});
