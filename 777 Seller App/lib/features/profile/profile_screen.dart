import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../auth/auth_provider.dart';
import 'locale_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {

  Future<void> _launchTelegram() async {
    // Telegram Support link
    final url = Uri.parse('https://t.me/Gateway777Support');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch support link';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open Telegram. Contact support at support@777.com',
            ),
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final locale = ref.watch(localeProvider);
    final isHindi = locale.languageCode == 'hi';
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgClr = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8F9FA);
    final cardClr = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderClr = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textPrim = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final textSec = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return AppScaffold(
      backgroundColor: bgClr,
      appBar: AppBar(
        title: Text(
          isHindi ? 'प्रोफ़ाइल सेटिंग्स' : 'Profile Settings',
          style: TextStyle(color: textPrim),
        ),
        backgroundColor: bgClr,
        iconTheme: IconThemeData(color: textPrim),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Info Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardClr,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderClr),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFE8F0FE),
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: isDark
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFF1A73E8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'Gateway Merchant',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrim,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'email@example.com',
                    style: TextStyle(fontSize: 13, color: textSec),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+91 ${user?.phone ?? "9999999999"}',
                    style: TextStyle(fontSize: 13, color: textSec),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isHindi ? 'सत्यापित मर्चेंट' : 'ACTIVE MERCHANT',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00E676),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Profile Options list
            Container(
              decoration: BoxDecoration(
                color: cardClr,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderClr),
              ),
              child: Column(
                children: [
                  // Language Toggle Option
                  ListTile(
                    leading: Icon(Icons.translate, color: textSec),
                    title: Text(
                      isHindi ? 'भाषा (Language)' : 'Language',
                      style: TextStyle(color: textPrim),
                    ),
                    subtitle: Text(
                      isHindi
                          ? 'वर्तमान भाषा: हिंदी'
                          : 'Current Language: English',
                      style: TextStyle(color: textSec),
                    ),
                    trailing: Switch(
                      value: isHindi,
                      onChanged: (val) {
                        ref.read(localeProvider.notifier).toggleLocale();
                      },
                      activeThumbColor: const Color(0xFF00E676),
                    ),
                  ),
                  Divider(height: 1, indent: 56, color: borderClr),

                  // Dark Theme Toggle Option
                  ListTile(
                    leading: Icon(
                      isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: textSec,
                    ),
                    title: Text(
                      isHindi ? 'डार्क थीम (Dark Theme)' : 'Dark Theme',
                      style: TextStyle(color: textPrim),
                    ),
                    subtitle: Text(
                      isHindi
                          ? (isDarkMode
                                ? 'डार्क मोड सक्रिय'
                                : 'लाइट मोड सक्रिय')
                          : (isDarkMode
                                ? 'Dark mode active'
                                : 'Light mode active'),
                      style: TextStyle(color: textSec),
                    ),
                    trailing: Switch(
                      value: isDarkMode,
                      onChanged: (val) {
                        ref.read(themeModeProvider.notifier).toggleTheme();
                      },
                      activeThumbColor: const Color(0xFF00E676),
                    ),
                  ),
                  Divider(height: 1, indent: 56, color: borderClr),

                  // Telegram Support Redirect
                  ListTile(
                    leading: Icon(Icons.send_rounded, color: textSec),
                    title: Text(
                      isHindi
                          ? 'सहायता केंद्र (Telegram)'
                          : 'Support Chat (Telegram)',
                      style: TextStyle(color: textPrim),
                    ),
                    subtitle: Text(
                      isHindi
                          ? 'हमारे शिकायत अधिकारियों से संपर्क करें'
                          : 'Chat directly with support desks',
                      style: TextStyle(color: textSec),
                    ),
                    trailing: Icon(Icons.chevron_right, color: textSec),
                    onTap: _launchTelegram,
                  ),
                  Divider(height: 1, indent: 56, color: borderClr),

                  // Change Bank Account Info / Payout Method
                  ListTile(
                    leading: Icon(Icons.account_balance, color: textSec),
                    title: Text(
                      isHindi
                          ? 'बैंक खाता / भुगतान विधि बदलें'
                          : 'Change Bank / Payout Method',
                      style: TextStyle(color: textPrim),
                    ),
                    subtitle: Text(
                      isHindi
                          ? 'अपना बैंक खाता और UPI विवरण अपडेट करें'
                          : 'Update your bank account & UPI details',
                      style: TextStyle(color: textSec),
                    ),
                    trailing: Icon(Icons.chevron_right, color: textSec),
                    onTap: () {
                      context.push('/bank-details');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sign out button
            OutlinedButton(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 1),
              ),
              child: Text(isHindi ? 'लॉग आउट' : 'Sign Out'),
            ),
            const SizedBox(height: 32),

            // Version info footer
            Text(
              'App Version: 9.1.6 (OTC Production Build)',
              style: TextStyle(
                fontSize: 12,
                color: textSec,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
