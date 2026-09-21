import "package:flutter_secure_storage/flutter_secure_storage.dart";

class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyAccessToken = "partner_access_token";
  static const String _keyPartnerId = "partner_id";
  static const String _keyPartnerName = "partner_name";
  static const String _keyPartnerEmail = "partner_email";
  static const String _keyReferralCode = "partner_referral_code";
  static const String _keyHostOverride = "partner_host_override";

  Future<void> saveSession({
    required String token,
    required String partnerId,
    required String name,
    required String email,
    required String referralCode,
  }) async {
    await _storage.write(key: _keyAccessToken, value: token);
    await _storage.write(key: _keyPartnerId, value: partnerId);
    await _storage.write(key: _keyPartnerName, value: name);
    await _storage.write(key: _keyPartnerEmail, value: email);
    await _storage.write(key: _keyReferralCode, value: referralCode);
  }

  Future<String?> getAccessToken() => _storage.read(key: _keyAccessToken);
  Future<String?> getPartnerId() => _storage.read(key: _keyPartnerId);
  Future<String?> getPartnerName() => _storage.read(key: _keyPartnerName);
  Future<String?> getPartnerEmail() => _storage.read(key: _keyPartnerEmail);
  Future<String?> getReferralCode() => _storage.read(key: _keyReferralCode);

  Future<String?> getHostOverride() => _storage.read(key: _keyHostOverride);
  Future<void> setHostOverride(String host) => _storage.write(key: _keyHostOverride, value: host);

  Future<void> clearSession() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyPartnerId);
    await _storage.delete(key: _keyPartnerName);
    await _storage.delete(key: _keyPartnerEmail);
    await _storage.delete(key: _keyReferralCode);
  }

  Future<bool> hasActiveSession() async {
    final token = await getAccessToken();
    final partnerId = await getPartnerId();
    return token != null && token.isNotEmpty && partnerId != null && partnerId.isNotEmpty;
  }
}
