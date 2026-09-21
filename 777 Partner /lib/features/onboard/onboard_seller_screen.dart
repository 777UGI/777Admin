import "package:flutter/foundation.dart";
import "../../core/env_config.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:url_launcher/url_launcher.dart";
import "../../core/theme/theme.dart";
import "../../core/utils/telegram_help_desk.dart";
import "../dashboard/partner_providers.dart";

class OnboardSellerScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToProfile;

  const OnboardSellerScreen({super.key, this.onNavigateToProfile});

  @override
  ConsumerState<OnboardSellerScreen> createState() => _OnboardSellerScreenState();
}

class _OnboardSellerScreenState extends ConsumerState<OnboardSellerScreen> {
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text("$label copied to clipboard!"),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareWhatsApp(String referralLink, String referralCode) async {
    final msg = """🚀 777 USDT Gateway India

💱 USDT Selling & Trading Services

Looking to explore USDT services?
Create your account with 777 USDT Gateway India and discover what the platform offers.

🔗 Join / Register Here:
$referralLink

⚡ Simple Registration
🌐 Easy Platform Access
📲 Get Started Online

Please review the platform details and eligibility requirements before using the service.""";

    final encoded = Uri.encodeComponent(msg);
    final nativeUri = Uri.parse("whatsapp://send?text=$encoded");
    final httpsUri = Uri.parse("https://api.whatsapp.com/send?text=$encoded");

    try {
      final launched = await launchUrl(nativeUri, mode: LaunchMode.externalNonBrowserApplication);
      if (!launched) {
        await launchUrl(httpsUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(httpsUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          _copyToClipboard(msg, "Invite Message");
        }
      }
    }
  }

  Future<void> _shareTelegram(String referralLink, String referralCode) async {
    final msg = """🚀 777 USDT Gateway India

💱 USDT Selling & Trading Services

Looking to explore USDT services?
Create your account with 777 USDT Gateway India and discover what the platform offers.

🔗 Join / Register Here:
$referralLink

⚡ Simple Registration
🌐 Easy Platform Access
📲 Get Started Online

Please review the platform details and eligibility requirements before using the service.""";

    final encoded = Uri.encodeComponent(msg);
    final nativeUri = Uri.parse("tg://msg?text=$encoded");
    final httpsUri = Uri.parse("https://t.me/share/url?url=${Uri.encodeComponent(referralLink)}&text=$encoded");

    try {
      final launched = await launchUrl(nativeUri, mode: LaunchMode.externalNonBrowserApplication);
      if (!launched) {
        await launchUrl(httpsUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(httpsUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          _copyToClipboard(referralLink, "Referral Link");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(partnerDashboardProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBackgroundColor,
      appBar: AppBar(
        title: const Text("Onboard Merchants"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryColor),
            onPressed: () => ref.invalidate(partnerDashboardProvider),
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.error),
                const SizedBox(height: 12),
                Text("Connection error: $err", style: const TextStyle(color: AppTheme.darkTextSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(partnerDashboardProvider),
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final partner = (data["partner"] as Map<String, dynamic>?) ?? {};
          final bank = (partner["bankDetails"] as Map<String, dynamic>?) ?? {};

          final partnerName = partner["name"]?.toString() ?? "Partner Agent";
          final partnerEmail = partner["email"]?.toString() ?? "";
          final referralCode = partner["referralCode"]?.toString() ?? "AGENT001";
          final commPercent = (partner["commissionPercent"] as num?)?.toDouble() ?? 0.50;
          final host = kIsWeb ? "localhost:8080" : EnvConfig.sellerHost;
          final referralLink = "http://$host/#/signup?ref=$referralCode";

          // Bank Details completeness check
          final hasAccount = (bank["accountNumber"]?.toString().trim().isNotEmpty ?? false);
          final hasUpi = (bank["upiId"]?.toString().trim().isNotEmpty ?? false);
          final isBankComplete = hasAccount || hasUpi;

          // ==========================================================
          // 1. LOCKED VIEW (Bank Details Incomplete)
          // ==========================================================
          if (!isBankComplete) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: AppTheme.cardDecoration(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_person_rounded, size: 44, color: AppTheme.warning),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Onboarding Hub Locked",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkTextPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Your account details are missing! Admin onboards partners without bank credentials. You must configure your payout Bank Account or UPI ID to unlock referral privileges and start earning commissions.",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.darkTextSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: widget.onNavigateToProfile,
                        icon: const Icon(Icons.account_balance_rounded, size: 18),
                        label: const Text("Setup Bank Details Now"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          final tgDesk = dashboardAsync.value?["support"]?["telegramAgent"]?.toString() ?? "therockymerchant";
                          TelegramHelpDesk.launchDesk(
                            partnerName: partnerName,
                            referralCode: referralCode,
                            partnerEmail: partnerEmail,
                            telegramUsername: tgDesk,
                            context: context,
                          );
                        },
                        icon: const Icon(Icons.support_agent_rounded, size: 18, color: AppTheme.info),
                        label: const Text("24/7 Agent Help Desk"),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // ==========================================================
          // 2. UNLOCKED VIEW (Full Merchant Onboarding Suite)
          // ==========================================================
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Hero Banner
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: AppTheme.heroCardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  "assets/partner_logo.jpeg",
                                  width: 38,
                                  height: 38,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "SELLER ONBOARDING",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${commPercent.toStringAsFixed(2)}% Commission",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "Onboard Sellers & Grow Your Network",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Every seller you register automatically earns you ${commPercent.toStringAsFixed(2)}% net commission on every USDT trade they complete.",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Card 1: VIP Referral Link Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.link_rounded, color: AppTheme.primaryColor, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Your VIP Referral Link",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkTextPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _copyToClipboard(referralLink, "Referral Link"),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.darkSurfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.darkBorderColor),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  referralLink,
                                  style: const TextStyle(
                                    color: AppTheme.primaryLight,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.copy_rounded, color: AppTheme.primaryColor, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _shareWhatsApp(referralLink, referralCode),
                              icon: const Icon(Icons.share_rounded, size: 18),
                              label: const Text("WhatsApp", style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _shareTelegram(referralLink, referralCode),
                              icon: const Icon(Icons.send_rounded, size: 18),
                              label: const Text("Telegram", style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0088CC),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Card 2: Referral Code Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecoration(),
                  child: InkWell(
                    onTap: () => _copyToClipboard(referralCode, "Referral Code"),
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Agent Referral Code",
                              style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              referralCode,
                              style: const TextStyle(
                                color: AppTheme.darkTextPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "Tap to copy • Sellers enter during signup",
                              style: TextStyle(color: AppTheme.primaryLight, fontSize: 11),
                            ),
                          ],
                        ),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.copy_rounded, color: AppTheme.primaryColor),
                          onPressed: () => _copyToClipboard(referralCode, "Referral Code"),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Card 3: How It Works 3-Step Guide
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "How Partner Commission Works",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkTextPrimary),
                      ),
                      const SizedBox(height: 16),
                      _buildStepItem(
                        step: "1",
                        title: "Share Your Link or Code",
                        desc: "Send your invite link to USDT sellers or give them your code $referralCode.",
                      ),
                      const SizedBox(height: 12),
                      _buildStepItem(
                        step: "2",
                        title: "Merchant Trades USDT",
                        desc: "Your referred sellers submit USDT deposit requests on the 777 Gateway.",
                      ),
                      const SizedBox(height: 12),
                      _buildStepItem(
                        step: "3",
                        title: "Earn Automatic ${commPercent.toStringAsFixed(2)}% Commission",
                        desc: "Upon deposit verification, your commission lands instantly in your wallet balance!",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Card 4: 24/7 Agent Help Desk
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecoration(),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.info.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.support_agent_rounded, color: AppTheme.info, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "24/7 Agent Help Desk",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkTextPrimary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Priority Telegram Support for Partner Agents",
                              style: TextStyle(fontSize: 12, color: AppTheme.darkTextSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        onPressed: () {
                          final tgDesk = dashboardAsync.value?["support"]?["telegramAgent"]?.toString() ?? "therockymerchant";
                          TelegramHelpDesk.launchDesk(
                            partnerName: partnerName,
                            referralCode: referralCode,
                            partnerEmail: partnerEmail,
                            telegramUsername: tgDesk,
                            context: context,
                          );
                        },
                        style: IconButton.styleFrom(backgroundColor: AppTheme.info),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepItem({
    required String step,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.4)),
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w900, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.darkTextPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: AppTheme.darkTextSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
