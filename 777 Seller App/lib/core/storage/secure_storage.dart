import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _apiHostOverrideKey = 'api_host_override';
  static const _phoneKey = 'temp_phone';

  final FlutterSecureStorage _storage;
  final Map<String, String> _memCache = {};

  SecureStorage() : _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      if (refreshToken != null) {
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
      }
    } catch (e) {
      _memCache[_accessTokenKey] = accessToken;
      if (refreshToken != null) {
        _memCache[_refreshTokenKey] = refreshToken;
      }
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey) ?? _memCache[_accessTokenKey];
    } catch (e) {
      return _memCache[_accessTokenKey];
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey) ?? _memCache[_refreshTokenKey];
    } catch (e) {
      return _memCache[_refreshTokenKey];
    }
  }

  Future<void> clearTokens() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
    } catch (e) {
      // ignore
    }
    _memCache.remove(_accessTokenKey);
    _memCache.remove(_refreshTokenKey);
  }

  Future<void> saveApiHostOverride(String host) async {
    try {
      await _storage.write(key: _apiHostOverrideKey, value: host);
    } catch (e) {
      _memCache[_apiHostOverrideKey] = host;
    }
  }

  Future<String?> getApiHostOverride() async {
    try {
      return await _storage.read(key: _apiHostOverrideKey) ?? _memCache[_apiHostOverrideKey];
    } catch (e) {
      return _memCache[_apiHostOverrideKey];
    }
  }

  Future<void> saveTempPhone(String phone) async {
    try {
      await _storage.write(key: _phoneKey, value: phone);
    } catch (e) {
      _memCache[_phoneKey] = phone;
    }
  }

  Future<String?> getTempPhone() async {
    try {
      return await _storage.read(key: _phoneKey) ?? _memCache[_phoneKey];
    } catch (e) {
      return _memCache[_phoneKey];
    }
  }

  Future<void> clearTempPhone() async {
    try {
      await _storage.delete(key: _phoneKey);
    } catch (e) {
      // ignore
    }
    _memCache.remove(_phoneKey);
  }
}
