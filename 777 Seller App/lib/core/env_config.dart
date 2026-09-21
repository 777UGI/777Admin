class EnvConfig {
  static Future<void> initialize() async {
    // No-op fallback logic, dotenv is removed
  }

  static String get environment => 'production';
  
  static bool get isTestnet => false;

  // Primary: Live Production Backend on Render
  static String get apiBaseUrl => 'https://seven77-backend-cn0p.onrender.com';
  
  // Secondary fallback: Local fallback
  static String get lanBaseUrl => 'http://127.0.0.1:5001';
}
