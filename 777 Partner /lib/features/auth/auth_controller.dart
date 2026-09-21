import "package:dio/dio.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../core/network/api_client.dart";

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? partnerId;
  final String? name;
  final String? email;
  final String? referralCode;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.partnerId,
    this.name,
    this.email,
    this.referralCode,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? partnerId,
    String? name,
    String? email,
    String? referralCode,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      partnerId: partnerId ?? this.partnerId,
      name: name ?? this.name,
      email: email ?? this.email,
      referralCode: referralCode ?? this.referralCode,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(() => checkActiveSession());
    return const AuthState();
  }

  Future<void> checkActiveSession() async {
    final storage = ref.read(secureStorageProvider);
    final hasSession = await storage.hasActiveSession();
    if (hasSession) {
      final id = await storage.getPartnerId();
      final name = await storage.getPartnerName();
      final email = await storage.getPartnerEmail();
      final refCode = await storage.getReferralCode();
      state = state.copyWith(
        isAuthenticated: true,
        partnerId: id,
        name: name,
        email: email,
        referralCode: refCode,
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dio = ref.read(dioProvider);
      final storage = ref.read(secureStorageProvider);

      final response = await dio.post(
        "/auth/login",
        data: {
          "email": email.trim(),
          "password": password.trim(),
        },
      );

      final data = response.data;
      if (data["success"] == true) {
        final user = data["user"];
        final token = data["token"] ?? "";
        final partnerId = user["_id"]?.toString() ?? user["id"]?.toString() ?? "";
        final name = user["name"]?.toString() ?? "Partner";
        final userEmail = user["email"]?.toString() ?? email;
        final refCode = user["referralCode"]?.toString() ?? "AGENT001";

        await storage.saveSession(
          token: token,
          partnerId: partnerId,
          name: name,
          email: userEmail,
          referralCode: refCode,
        );

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          partnerId: partnerId,
          name: name,
          email: userEmail,
          referralCode: refCode,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: data["error"] ?? "Login failed. Invalid credentials.",
        );
        return false;
      }
    } on DioException catch (e) {
      String msg = "Unable to connect to server.";
      if (e.response?.data != null && e.response?.data["error"] != null) {
        msg = e.response?.data["error"].toString() ?? msg;
      }
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    final storage = ref.read(secureStorageProvider);
    await storage.clearSession();
    state = const AuthState();
  }
}

final authControllerProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
