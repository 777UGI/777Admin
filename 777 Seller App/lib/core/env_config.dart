class EnvConfig {
  static Future<void> initialize() async {
    // No-op fallback logic, dotenv is removed
  }

  static String get environment => 'production';
  
  static bool get isTestnet => false;

  // Primary: 127.0.0.1:5001 (ADB reverse via USB on phone)
  static String get apiBaseUrl => 'http://127.0.0.1:5001';
  
  // Secondary fallback: Current Mac LAN IP on Wi-Fi
  static String get lanBaseUrl => 'http://10.116.176.136:5001';
}
