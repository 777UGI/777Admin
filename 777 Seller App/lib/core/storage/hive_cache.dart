import 'package:hive_flutter/hive_flutter.dart';

class HiveCache {
  static const String _settingsBoxName = 'settings_box';
  static const String _notificationsBoxName = 'notifications_box';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(_settingsBoxName);
    await Hive.openBox(_notificationsBoxName);
  }

  static Box get settingsBox => Hive.box(_settingsBoxName);
  static Box get notificationsBox => Hive.box(_notificationsBoxName);

  static Future<void> cacheExchangeRate(double rate) async {
    await settingsBox.put('exchange_rate', rate);
  }

  static double getCachedExchangeRate(double fallback) {
    return settingsBox.get('exchange_rate', defaultValue: fallback);
  }

  static Future<void> cacheWallets(Map<String, String> wallets) async {
    await settingsBox.put('wallets', wallets);
  }

  static Map<String, String> getCachedWallets() {
    final dynamic val = settingsBox.get('wallets');
    if (val is Map) {
      return Map<String, String>.from(val);
    }
    return {};
  }

  static Future<void> clearAll() async {
    await settingsBox.clear();
    await notificationsBox.clear();
  }
}
