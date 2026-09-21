import "package:dio/dio.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../core/network/api_client.dart";
import "../auth/auth_controller.dart";

// Dashboard Data Provider
final partnerDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  final partnerId = auth.partnerId;
  if (partnerId == null || partnerId.isEmpty) {
    throw Exception("Authentication required");
  }

  final dio = ref.watch(dioProvider);
  final response = await dio.get("/partner/dashboard/$partnerId");
  if (response.data["success"] == true) {
    return response.data as Map<String, dynamic>;
  }
  throw Exception(response.data["error"] ?? "Failed to load dashboard");
});

// Merchants Provider
final partnerMerchantsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  final partnerId = auth.partnerId;
  if (partnerId == null || partnerId.isEmpty) return [];

  final dio = ref.watch(dioProvider);
  final response = await dio.get("/partner/merchants/$partnerId");
  if (response.data["success"] == true) {
    final list = response.data["merchants"] as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return [];
});

// Transactions / Ledger Provider
final partnerTransactionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  final partnerId = auth.partnerId;
  if (partnerId == null || partnerId.isEmpty) return [];

  final dio = ref.watch(dioProvider);
  final response = await dio.get("/partner/transactions/$partnerId");
  if (response.data["success"] == true) {
    final list = response.data["transactions"] as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return [];
});

// Bank Details Provider
final partnerBankDetailsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  final partnerId = auth.partnerId;
  if (partnerId == null || partnerId.isEmpty) return {};

  final dio = ref.watch(dioProvider);
  final response = await dio.get("/partner/bank-details/$partnerId");
  if (response.data["success"] == true) {
    return Map<String, dynamic>.from(response.data["bankDetails"] as Map? ?? {});
  }
  return {};
});

// Withdrawals History Provider
final partnerWithdrawalsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  final partnerId = auth.partnerId;
  if (partnerId == null || partnerId.isEmpty) return [];

  final dio = ref.watch(dioProvider);
  final response = await dio.get("/partner/withdrawals/$partnerId");
  if (response.data["success"] == true) {
    final list = response.data["withdrawals"] as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return [];
});

// Action Service Provider
class PartnerActionService {
  final Dio _dio;
  final Ref _ref;

  PartnerActionService(this._dio, this._ref);

  Future<bool> saveBankDetails({
    required String bankName,
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
    String? upiId,
  }) async {
    final auth = _ref.read(authControllerProvider);
    final partnerId = auth.partnerId;
    if (partnerId == null) return false;

    final res = await _dio.post(
      "/partner/bank-details",
      data: {
        "partnerId": partnerId,
        "bankName": bankName,
        "accountHolderName": accountHolderName,
        "accountNumber": accountNumber,
        "ifscCode": ifscCode,
        "upiId": upiId ?? "",
      },
    );

    if (res.data["success"] == true) {
      _ref.invalidate(partnerBankDetailsProvider);
      _ref.invalidate(partnerDashboardProvider);
      return true;
    }
    return false;
  }

  Future<Map<String, dynamic>> requestWithdrawal({
    required double amountInr,
    required double amountUsdt,
  }) async {
    final auth = _ref.read(authControllerProvider);
    final partnerId = auth.partnerId;
    if (partnerId == null) return {"success": false, "error": "Not authenticated"};

    try {
      final res = await _dio.post(
        "/partner/withdraw",
        data: {
          "partnerId": partnerId,
          "amountInr": amountInr,
          "amountUsdt": amountUsdt,
          "payoutMethod": "BANK_TRANSFER",
        },
      );

      if (res.data["success"] == true) {
        _ref.invalidate(partnerWithdrawalsProvider);
        _ref.invalidate(partnerDashboardProvider);
        return {"success": true, "withdrawal": res.data["withdrawal"]};
      } else {
        return {"success": false, "error": res.data["error"] ?? "Withdrawal failed"};
      }
    } on DioException catch (e) {
      return {
        "success": false,
        "error": e.response?.data?["error"] ?? e.message ?? "Server error",
      };
    }
  }
}

final partnerActionServiceProvider = Provider<PartnerActionService>((ref) {
  final dio = ref.watch(dioProvider);
  return PartnerActionService(dio, ref);
});
