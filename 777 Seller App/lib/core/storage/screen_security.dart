import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

class ScreenSecurity {
  static Future<void> protectScreen() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid) {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      }
      // Note: On iOS, screenshot blocking is handled natively by the OS 
      // or using custom secure text field overlays which is the only way on iOS.
    } catch (e) {
      debugPrint('Screen protection error: $e');
    }
  }

  static Future<void> unprotectScreen() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid) {
        await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      }
    } catch (e) {
      debugPrint('Screen unprotection error: $e');
    }
  }
}
