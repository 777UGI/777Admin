import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../auth/auth_provider.dart';
import '../bank_details/bank_provider.dart';
import '../transactions/transactions_provider.dart';
import 'rate_provider.dart';
import '../notifications/notifications_provider.dart';

final onlineStatusProvider = StateProvider<bool>((ref) => true);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _formatIndianCurrency(double value) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(authProvider).user;
    final bankState = ref.watch(bankDetailsNotifierProvider);
    final txState = ref.watch(transactionsNotifierProvider);
    final notifications = ref.watch(notificationsNotifierProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;

    final isBankComplete = bankState.accountNumber.isNotEmpty || bankState.upiId.isNotEmpty;

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(settingsNotifierProvider.notifier).fetchSettings();
          await ref.read(transactionsNotifierProvider.notifier).fetchDashboard();
          await ref.read(bankDetailsNotifierProvider.notifier).fetchBankDetails();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: true,
              pinned: true,
              stretch: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              scrolledUnderElevation: 2,
              flexibleSpace: FlexibleSpaceBar(
                expandedTitleScale: 1.2,
                titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                title: Text(
                  'Hello, ${user?.name ?? "Merchant"} 👋',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                background: Container(color: theme.scaffoldBackgroundColor),
              ),
              actions: [
                IconButton(
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    backgroundColor: colorScheme.error,
                    label: Text('$unreadCount'),
                    child: const Icon(Icons.notifications_none_rounded),
                  ),
                  onPressed: () => context.go('/notifications'),
                ),
                IconButton(
                  icon: const Icon(Icons.account_circle_outlined),
                  onPressed: () => context.go('/profile'),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildAvailableBalanceCard(context, ref, isBankComplete),
                  const SizedBox(height: 24),
                  _buildLiveRateSection(context, ref),
                  const SizedBox(height: 24),
                  _buildQuickAction(context, isBankComplete),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Performance Overview', style: theme.textTheme.titleMedium),
                      TextButton(
                        onPressed: () => context.push('/history'),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatsGrid(context, txState),
                  const SizedBox(height: 32),
                  Text('Getting Started', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _buildConfigChecklist(context, isBankComplete),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableBalanceCard(BuildContext context, WidgetRef ref, bool isBankComplete) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rateSettings = ref.watch(settingsNotifierProvider);
    final txState = ref.watch(transactionsNotifierProvider);

    final approvedTxs = txState.transactions.where(
      (t) => t.status == 'approved' || t.status == 'confirmed' || t.status == 'verified',
    ).toList();

    final liveRate = rateSettings.exchangeRate > 0 ? rateSettings.exchangeRate : 93.50;
    final availableInrBalance = approvedTxs.fold<double>(
      0.0,
      (sum, t) => sum + (t.amountUsdt * (t.rateLockedInr > 0 ? t.rateLockedInr : liveRate)),
    );
    final totalApprovedUsdt = approvedTxs.fold<double>(0.0, (sum, t) => sum + t.amountUsdt);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withBlue(150)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Payout',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (isBankComplete) {
                        context.push('/deposit');
                      } else {
                        _showBankRequiredDialog(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const Text('Start Selling', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ThemeToggleSwitch(
                    value: ref.watch(onlineStatusProvider),
                    onChanged: (val) {
                      ref.read(onlineStatusProvider.notifier).state = val;
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatIndianCurrency(availableInrBalance),
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Calculated from ${totalApprovedUsdt.toStringAsFixed(2)} USDT',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveRateSection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rateSettings = ref.watch(settingsNotifierProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.trending_up_rounded, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Buying Rate (INR)', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    '${_formatIndianCurrency(rateSettings.exchangeRate)} / USDT',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, bool isBankComplete) {
    return GestureDetector(
      onTap: () {
        if (isBankComplete) {
          context.push('/deposit');
        } else {
          _showBankRequiredDialog(context);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9933), Color(0xFF138808)], // Always Tricolor
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF138808).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'SELL USDT NOW',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, TransactionsState txState) {
    final completedCount = txState.transactions.where((tx) => tx.status == 'paid' || tx.payout?.status == 'paid').length;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(context, 'Total Sold', '${txState.totalUsdtSold.toStringAsFixed(1)} USDT', Icons.account_balance_wallet_outlined),
        _buildStatCard(context, 'Total Earned', _formatIndianCurrency(txState.totalInrReceived), Icons.payments_outlined),
        _buildStatCard(context, 'Completed', completedCount.toString(), Icons.check_circle_outline_rounded),
        _buildStatCard(context, 'Active Trades', (txState.transactions.length - completedCount).toString(), Icons.hourglass_empty_rounded),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigChecklist(BuildContext context, bool isBankComplete) {
    return Card(
      child: Column(
        children: [
          _buildChecklistItem(
            context,
            title: 'Bank Details',
            subtitle: isBankComplete ? 'Configured successfully' : 'Not setup yet',
            isComplete: isBankComplete,
            onTap: () => context.push('/bank-details'),
          ),
          const Divider(indent: 60),
          _buildChecklistItem(
            context,
            title: 'Account Verification',
            subtitle: 'Identity verified',
            isComplete: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isComplete,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isComplete ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isComplete ? Icons.check_rounded : Icons.priority_high_rounded,
          color: isComplete ? Colors.green : Colors.orange,
          size: 20,
        ),
      ),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
    );
  }

  void _showBankRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setup Bank Payout'),
        content: const Text('Please configure your bank account or UPI details to unlock USDT selling and receive INR payouts.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/bank-details');
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Add Details Now'),
          ),
        ],
      ),
    );
  }
}


class ThemeToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const ThemeToggleSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final width = 64.0;
    final height = 28.0;
    final circleSize = 20.0;
    final padding = (height - circleSize) / 2;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          color: value ? const Color(0xFF2A2A2A) : const Color(0xFFEFEFEF),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Stack(
          children: [
            // OFF Text
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: value ? 0.0 : 1.0,
                  child: const Text('OFF', style: TextStyle(color: Color(0xFF2A2A2A), fontSize: 10, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
            // ON Text
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: value ? 1.0 : 0.0,
                  child: const Text('ON', style: TextStyle(color: Color(0xFFEFEFEF), fontSize: 10, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              top: padding,
              left: value ? (width - circleSize - padding) : padding,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? const Color(0xFFEFEFEF) : const Color(0xFF2A2A2A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
