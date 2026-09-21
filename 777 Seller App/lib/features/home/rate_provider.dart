import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../auth/auth_provider.dart';

class SettingsData {
  final double exchangeRate;
  final Map<String, String> wallets;
  final bool loading;
  final String? error;

  SettingsData({
    this.exchangeRate = 88.5,
    this.wallets = const {},
    this.loading = false,
    this.error,
  });

  SettingsData copyWith({
    double? exchangeRate,
    Map<String, String>? wallets,
    bool? loading,
    String? error,
  }) {
    return SettingsData(
      exchangeRate: exchangeRate ?? this.exchangeRate,
      wallets: wallets ?? this.wallets,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsData> {
  final ApiClient _apiClient;
  Timer? _pollingTimer;

  SettingsNotifier(this._apiClient) : super(SettingsData()) {
    fetchSettings();
    startPolling();
  }

  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      fetchSettings(isPolling: true);
    });
  }

  Future<void> fetchSettings({bool isPolling = false}) async {
    if (!isPolling) {
      state = state.copyWith(loading: true);
    }
    try {
      debugPrint('[RateProvider] Calling GET /api/public/settings...');
      final response = await _apiClient.dio.get('/api/public/settings');
      debugPrint('[RateProvider] Got settings response: ${response.statusCode}, ${response.data}');
      if (response.statusCode == 200 && response.data != null) {
        final rate =
            (response.data['exchangeRate'] as num?)?.toDouble() ?? 88.5;
        final rawWallets = response.data['wallets'];
        Map<String, String> wallets = {};
        if (rawWallets is Map) {
          wallets = Map<String, String>.from(rawWallets);
        }
        state = SettingsData(
          exchangeRate: rate,
          wallets: wallets,
          loading: false,
        );
      }
    } catch (e) {
      debugPrint('[RateProvider] Error fetching settings: $e');
      if (!isPolling) {
        state = state.copyWith(
          loading: false,
          error: 'Failed to load rate settings.',
        );
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, SettingsData>((ref) {
      final client = ref.watch(apiClientProvider);
      return SettingsNotifier(client);
    });
