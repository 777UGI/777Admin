class EnvConfig {
  static const String defaultHost = "127.0.0.1:5001";
  static const String localhost = "127.0.0.1:5001";
  static const String lanHost = "10.116.176.136:5001";
  static const String sellerHost = "10.116.176.136:8080";
  static String get sellerWebUrl => "http://10.116.176.136:8080";
  static const String androidEmulatorHost = "10.116.176.136:5001";

  static String get apiBaseUrl => "https://seven77-backend-cn0p.onrender.com/api";
  static String get fallbackBaseUrl => "https://seven77-backend-cn0p.onrender.com/api";
  static String get lanBaseUrl => "http://127.0.0.1:5001/api";
  
  static const bool isProduction = true;
}
