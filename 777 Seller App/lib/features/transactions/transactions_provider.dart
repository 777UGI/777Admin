import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../auth/auth_provider.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String txHash;
  final double amountUsdt;
  final String network;
  final double rateLockedInr;
  final String status; // pending, confirmed, verified, rejected
  final String createdAt;
  final PayoutModel? payout;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.txHash,
    required this.amountUsdt,
    required this.network,
    required this.rateLockedInr,
    required this.status,
    required this.createdAt,
    this.payout,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      txHash: json['txHash'] as String,
      amountUsdt: (json['amountUsdt'] as num?)?.toDouble() ?? 0.0,
      network: json['network'] as String? ?? 'Unknown',
      rateLockedInr: (json['rateLockedInr'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      payout: json['payout'] != null
          ? PayoutModel.fromJson(json['payout'])
          : null,
    );
  }
}

class PayoutModel {
  final String id;
  final String? depositId;
  final String userId;
  final double amountInr;
  final String payoutMethod;
  final String status; // pending, paid
  final String? paidAt;
  final String? payoutReference;
  final String? payoutScreenshot;

  PayoutModel({
    required this.id,
    this.depositId,
    required this.userId,
    required this.amountInr,
    required this.payoutMethod,
    required this.status,
    this.paidAt,
    this.payoutReference,
    this.payoutScreenshot,
  });

  factory PayoutModel.fromJson(Map<String, dynamic> json) {
    return PayoutModel(
      id: json['id'] as String,
      depositId: json['depositId'] as String?,
      userId: json['userId'] as String,
      amountInr: (json['amountInr'] as num?)?.toDouble() ?? 0.0,
      payoutMethod: json['payoutMethod'] as String? ?? 'Bank',
      status: json['status'] as String? ?? 'pending',
      paidAt: json['paidAt'] as String?,
      payoutReference: json['payoutReference'] as String?,
      payoutScreenshot: json['payoutScreenshot'] as String?,
    );
  }
}

class TransactionsState {
  final List<TransactionModel> transactions;
  final double totalUsdtSold;
  final double totalInrReceived;
  final bool loading;
  final String? error;

  TransactionsState({
    this.transactions = const [],
    this.totalUsdtSold = 0.0,
    this.totalInrReceived = 0.0,
    this.loading = false,
    this.error,
  });

  TransactionsState copyWith({
    List<TransactionModel>? transactions,
    double? totalUsdtSold,
    double? totalInrReceived,
    bool? loading,
    String? error,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      totalUsdtSold: totalUsdtSold ?? this.totalUsdtSold,
      totalInrReceived: totalInrReceived ?? this.totalInrReceived,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final ApiClient _apiClient;
  final Ref _ref;

  TransactionsNotifier(this._apiClient, this._ref)
    : super(TransactionsState()) {
    // Listen to auth status changes to reload automatically
    _ref.listen(authProvider, (previous, next) {
      if (next.user != null) {
        fetchDashboard();
      } else {
        state = TransactionsState();
      }
    });

    if (_ref.read(authProvider).user != null) {
      fetchDashboard();
    }
  }

  Future<void> fetchDashboard() async {
    state = state.copyWith(loading: true);
    try {
      final response = await _apiClient.dio.get('/api/seller/dashboard');
      if (response.statusCode == 200 && response.data != null) {
        final rawTx = response.data['transactions'] as List? ?? [];
        final txList = rawTx
            .map((x) => TransactionModel.fromJson(x as Map<String, dynamic>))
            .toList();

        // Update KYC status locally to match server dashboard state
        final newKycStatus = response.data['kycStatus'] as String?;
        if (newKycStatus != null) {
          _ref.read(authProvider.notifier).updateKycStatus(newKycStatus);
        }

        // Calculate statistics
        // Total USDT Sold = sum of verified/confirmed/paid deposits
        final totalUsdt = txList
            .where(
              (tx) =>
                  tx.status == 'verified' ||
                  tx.status == 'confirmed' ||
                  tx.status == 'paid',
            )
            .fold(0.0, (sum, tx) => sum + tx.amountUsdt);

        // Total INR Received = sum of paid payouts
        final totalInr = txList
            .where((tx) => tx.payout?.status == 'paid')
            .fold(0.0, (sum, tx) => sum + (tx.payout?.amountInr ?? 0.0));

        state = TransactionsState(
          transactions: txList,
          totalUsdtSold: totalUsdt,
          totalInrReceived: totalInr,
          loading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Failed to load transaction history.',
      );
    }
  }

  // Create new deposit trade
  Future<TransactionModel?> createDeposit({
    required double amountUsdt,
    required String network,
    required String txHash,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final response = await _apiClient.dio.post(
        '/api/seller/deposit',
        data: {
          'amountUsdt': amountUsdt,
          'network': network,
          'txHash': txHash.trim(),
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        final newDep = TransactionModel.fromJson(response.data['deposit']);
        await fetchDashboard(); // Reload history & stats
        return newDep;
      }
    } on DioException catch (e) {
      final msg =
          e.response?.data['error'] ?? 'Failed to submit deposit trade.';
      state = state.copyWith(loading: false, error: msg);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'An unexpected network error occurred.',
      );
    }
    return null;
  }
}

final transactionsNotifierProvider =
    StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
      final client = ref.watch(apiClientProvider);
      return TransactionsNotifier(client, ref);
    });
