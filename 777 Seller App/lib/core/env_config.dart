class EnvConfig {
  static Future<void> initialize() async {
    // No-op fallback logic, dotenv is removed
  }

  static String get environment => 'production';
  
  static bool get isTestnet => false;

  static String get apiBaseUrl => 'https://api.777gateway.com'; // Production API endpoint
}
