import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../auth/auth_provider.dart';

import 'dart:typed_data';

class BankDetailsState {
  final String accountNumber;
  final String confirmAccountNumber;
  final String ifscCode;
  final String accountHolderName;
  final String upiId;
  final File? upiQrFile;
  final Uint8List? upiQrBytes;
  final String? upiQrFileName;
  final String? upiQrUrl;

  final String bankName;
  final bool loading;
  final String? error;
  final bool isSaved;

  // Verification security
  final bool isOtpSent;
  final bool isOtpVerified;

  BankDetailsState({
    this.accountNumber = '',
    this.confirmAccountNumber = '',
    this.ifscCode = '',
    this.accountHolderName = '',
    this.upiId = '',
    this.upiQrFile,
    this.upiQrBytes,
    this.upiQrFileName,
    this.upiQrUrl,
    this.bankName = '',
    this.loading = false,
    this.error,
    this.isSaved = false,
    this.isOtpSent = false,
    this.isOtpVerified = false,
  });

  BankDetailsState copyWith({
    String? accountNumber,
    String? confirmAccountNumber,
    String? ifscCode,
    String? accountHolderName,
    String? upiId,
    File? upiQrFile,
    Uint8List? upiQrBytes,
    String? upiQrFileName,
    String? upiQrUrl,
    String? bankName,
    bool? loading,
    String? error,
    bool? isSaved,
    bool? isOtpSent,
    bool? isOtpVerified,
  }) {
    return BankDetailsState(
      accountNumber: accountNumber ?? this.accountNumber,
      confirmAccountNumber: confirmAccountNumber ?? this.confirmAccountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      upiId: upiId ?? this.upiId,
      upiQrFile: upiQrFile ?? this.upiQrFile,
      upiQrBytes: upiQrBytes ?? this.upiQrBytes,
      upiQrFileName: upiQrFileName ?? this.upiQrFileName,
      upiQrUrl: upiQrUrl ?? this.upiQrUrl,
      bankName: bankName ?? this.bankName,
      loading: loading ?? this.loading,
      error: error, // Can clear by passing null
      isSaved: isSaved ?? this.isSaved,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      isOtpVerified: isOtpVerified ?? this.isOtpVerified,
    );
  }
}

class BankDetailsNotifier extends StateNotifier<BankDetailsState> {
  final ApiClient _apiClient;

  BankDetailsNotifier(this._apiClient) : super(BankDetailsState()) {
    fetchBankDetails();
  }

  Future<void> fetchBankDetails() async {
    state = state.copyWith(loading: true);
    try {
      final response = await _apiClient.dio.get('/api/seller/payout-details');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        state = BankDetailsState(
          accountNumber: data['accountNumber'] ?? '',
          confirmAccountNumber: data['accountNumber'] ?? '',
          ifscCode: data['ifscCode'] ?? '',
          accountHolderName: data['accountHolderName'] ?? '',
          upiId: data['upiId'] ?? '',
          upiQrUrl: data['upiQrUrl'],
        );
        if (state.ifscCode.isNotEmpty) {
          await lookupIfsc(state.ifscCode);
        }
      } else {
        state = BankDetailsState();
      }
    } catch (e) {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> lookupIfsc(String ifsc) async {
    if (ifsc.length < 11) return;
    try {
      // Fetch details from razorpay public IFSC API
      final response = await Dio().get('https://ifsc.razorpay.com/$ifsc');
      if (response.statusCode == 200 && response.data != null) {
        final bankName = response.data['BANK'] as String? ?? 'Verified Bank';
        state = state.copyWith(bankName: bankName, error: null);
      }
    } catch (e) {
      state = state.copyWith(bankName: 'Self-Declared Bank');
    }
  }

  // Trigger modification OTP
  Future<bool> sendModificationOtp() async {
    state = state.copyWith(loading: true, error: null);
    try {
      // Simulate SMS OTP send
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(loading: false, isOtpSent: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Failed to send verification code.',
      );
      return false;
    }
  }

  // Verify modification OTP
  Future<bool> verifyModificationOtp(String otp) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (otp == '123456') {
        state = state.copyWith(
          loading: false,
          isOtpVerified: true,
          isOtpSent: false,
        );
        return true;
      } else {
        state = state.copyWith(
          loading: false,
          error: 'Invalid verification code.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Verification failed.');
      return false;
    }
  }

  // Submit Bank/Payout Details
  Future<bool> saveBankDetails() async {
    if (!state.isOtpVerified) {
      state = state.copyWith(
        error: 'OTP verification is mandatory before updating bank details.',
      );
      return false;
    }

    state = state.copyWith(loading: true, error: null);
    try {
      final dataMap = {
        'accountNumber': state.accountNumber.trim(),
        'ifscCode': state.ifscCode.trim().toUpperCase(),
        'accountHolderName': state.accountHolderName.trim(),
        'upiId': state.upiId.trim(),
      };

      final formData = FormData.fromMap(dataMap);
      if (state.upiQrBytes != null) {
        formData.files.add(
          MapEntry(
            'upiQr',
            MultipartFile.fromBytes(
              state.upiQrBytes!,
              filename: state.upiQrFileName ?? 'upi_qr.jpg',
            ),
          ),
        );
      } else if (state.upiQrFile != null) {
        formData.files.add(
          MapEntry(
            'upiQr',
            await MultipartFile.fromFile(
              state.upiQrFile!.path,
              filename: 'upi_qr.jpg',
            ),
          ),
        );
      }

      final response = await _apiClient.dio.post(
        '/api/seller/payout-details',
        data: formData,
      );

      if (response.statusCode == 200) {
        state = state.copyWith(
          loading: false,
          isSaved: true,
          isOtpVerified: false, // Reset OTP guard
        );
        fetchBankDetails();
        return true;
      } else {
        state = state.copyWith(
          loading: false,
          error: response.data['error'] ?? 'Failed to save payout details.',
        );
        return false;
      }
    } on DioException catch (e) {
      final msg =
          e.response?.data['error'] ?? 'Server error saving bank details.';
      state = state.copyWith(loading: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'An unexpected error occurred.',
      );
      return false;
    }
  }

  void updateField({
    String? accountNumber,
    String? confirmAccountNumber,
    String? ifscCode,
    String? accountHolderName,
    String? upiId,
    File? upiQrFile,
    Uint8List? upiQrBytes,
    String? upiQrFileName,
  }) {
    state = state.copyWith(
      accountNumber: accountNumber,
      confirmAccountNumber: confirmAccountNumber,
      ifscCode: ifscCode,
      accountHolderName: accountHolderName,
      upiId: upiId,
      upiQrFile: upiQrFile,
      upiQrBytes: upiQrBytes,
      upiQrFileName: upiQrFileName,
      isSaved: false, // Reset saved status on modification
    );
  }

  void resetVerification() {
    state = state.copyWith(isOtpSent: false, isOtpVerified: false, error: null);
  }
}

final bankDetailsNotifierProvider =
    StateNotifierProvider<BankDetailsNotifier, BankDetailsState>((ref) {
      final client = ref.watch(apiClientProvider);
      return BankDetailsNotifier(client);
    });
