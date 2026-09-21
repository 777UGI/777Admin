import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:intl/intl.dart";
import "package:url_launcher/url_launcher.dart";

class TelegramHelpDesk {
  static String cleanUsername(String? username) {
    if (username == null || username.trim().isEmpty) {
      return "therockymerchant";
    }
    return username
        .replaceAll("@", "")
        .replaceAll("https://t.me/", "")
        .replaceAll("http://t.me/", "")
        .replaceAll("t.me/", "")
        .split("?")
        .first
        .replaceAll("/", "")
        .trim();
  }

  static Future<void> launchDesk({
    required String partnerName,
    required String referralCode,
    required String partnerEmail,
    String? telegramUsername,
    BuildContext? context,
  }) async {
    final now = DateTime.now();
    final timeStr = DateFormat("dd MMM yyyy, hh:mm a").format(now);

    final message = '''Hello 777 Support Team,

I need assistance regarding my Partner Agent account.

📋 Agent Details:
• Name: $partnerName
• Agent Code: $referralCode
• Registered Email: $partnerEmail
• Time of Request: $timeStr IST

Query / Issue:
''';

    // 1. Copy details to clipboard automatically
    try {
      await Clipboard.setData(ClipboardData(text: message));
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("📋 Agent details copied! Just paste and send in chat."),
            backgroundColor: Color(0xFF00E676),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {}

    final cleanUser = cleanUsername(telegramUsername);

    // 2. Launch Telegram directly into the chat with the clean username
    final nativeUri = Uri.parse("tg://resolve?domain=$cleanUser");
    final httpsUri = Uri.parse("https://t.me/$cleanUser");

    try {
      final launched = await launchUrl(nativeUri, mode: LaunchMode.externalNonBrowserApplication);
      if (!launched) {
        await launchUrl(httpsUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(httpsUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint("Could not launch telegram: $e");
      }
    }
  }

  static Future<void> requestPartnerAccess({
    required String name,
    required String email,
    required String phone,
    String? telegramUsername,
    BuildContext? context,
  }) async {
    final message = '''📋 Partner Onboarding Request

Hello 777 USDT Gateway Team,

I would like to onboard as a partner with 777 USDT Gateway and request you to create my Partner ID/account.

My details have been collected through the app:

👤 Name: $name
📧 Email: $email
📱 Phone Number: $phone

Please review my details and proceed with my partner onboarding and account creation.

Thank you.''';

    // 1. Copy details to clipboard automatically
    try {
      await Clipboard.setData(ClipboardData(text: message));
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("📋 Details copied! Just paste and send in Telegram."),
            backgroundColor: Color(0xFF00E676),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {}

    final cleanUser = cleanUsername(telegramUsername);

    // 2. Launch direct Telegram chat
    final nativeUri = Uri.parse("tg://resolve?domain=$cleanUser");
    final httpsUri = Uri.parse("https://t.me/$cleanUser");

    try {
      final launched = await launchUrl(nativeUri, mode: LaunchMode.externalNonBrowserApplication);
      if (!launched) {
        await launchUrl(httpsUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(httpsUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint("Could not launch telegram: $e");
      }
    }
  }
}
