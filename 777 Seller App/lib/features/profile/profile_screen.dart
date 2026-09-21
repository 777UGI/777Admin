import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../auth/auth_provider.dart';
import '../home/rate_provider.dart';
import '../transactions/transactions_provider.dart';
import 'locale_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {

  Future<void> _launchTelegram() async {
    final nativeUrl = Uri.parse('tg://resolve?domain=therockymerchant');
    final webUrl = Uri.parse('https://t.me/therockymerchant');
    try {
      final launched = await launchUrl(nativeUrl, mode: LaunchMode.externalNonBrowserApplication);
      if (!launched) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Telegram.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;
    final locale = ref.watch(localeProvider);
    final isHindi = locale.languageCode == 'hi';
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return AppScaffold(
      appBar: AppBar(
        title: Text(isHindi ? 'प्रोफ़ाइल' : 'Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // User Header
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.primary, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          child: Icon(Icons.person_rounded, size: 60, color: theme.colorScheme.primary),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                          ),
                          child: const Icon(Icons.verified_rounded, size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'Gateway Merchant',
                    style: theme.textTheme.headlineMedium,
                  ),
                  Text(
                    user?.email ?? 'email@example.com',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isHindi ? 'सत्यापित मर्चेंट' : 'ACTIVE MERCHANT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Settings List
            Align(alignment: Alignment.centerLeft, child: Text('App Preferences', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    _buildSettingTile(
                      context,
                      icon: isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      title: isHindi ? 'डार्क थीम' : 'Dark Theme',
                      subtitle: isDarkMode ? 'Dark mode ON' : 'Light mode ON',
                      trailing: Switch(
                        value: isDarkMode,
                        onChanged: (val) => ref.read(themeModeProvider.notifier).toggleTheme(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Align(alignment: Alignment.centerLeft, child: Text('Account & Support', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    _buildSettingTile(
                      context,
                      icon: Icons.account_balance_rounded,
                      title: isHindi ? 'भुगतान विधि' : 'Payout Method',
                      subtitle: isHindi ? 'बैंक और UPI विवरण' : 'Bank & UPI details',
                      onTap: () => context.push('/bank-details'),
                    ),
                    const Divider(indent: 56, height: 1),
                    _buildSettingTile(
                      context,
                      icon: Icons.support_agent_rounded,
                      title: isHindi ? 'सहायता' : 'Support',
                      subtitle: isHindi ? 'टेलीग्राम सहायता' : 'Telegram Chat',
                      onTap: _launchTelegram,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: Text(isHindi ? 'लॉग आउट' : 'Sign Out', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'App Version: 9.1.6 (Production)',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 20),
      ),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 20),
    );
  }
}
