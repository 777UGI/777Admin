import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../auth/auth_provider.dart';
import '../bank_details/bank_provider.dart';
import '../transactions/transactions_provider.dart';
import 'rate_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _formatIndianCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final rateSettings = ref.watch(settingsNotifierProvider);
    final bankState = ref.watch(bankDetailsNotifierProvider);
    final txState = ref.watch(transactionsNotifierProvider);

    final isBankComplete = bankState.accountNumber.isNotEmpty || bankState.upiId.isNotEmpty;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgClr = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8F9FA);
    final cardClr = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderClr = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrim = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final textSec = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return AppScaffold(
      backgroundColor: bgClr,
      appBar: AppBar(
        title: const Text('777 USDT Gateway India'),
        centerTitle: false,
        backgroundColor: bgClr,
        actions: [
          IconButton(
            icon: const Badge(
              label: Text('1'),
              child: Icon(Icons.notifications_outlined),
            ),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        selectedItemColor: isDark ? const Color(0xFF00E676) : const Color(0xFF0F9D58),
        unselectedItemColor: textSec,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Ledger'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Sell'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          if (index == 1) context.push('/history');
          if (index == 2) {
            if (isBankComplete) {
              context.push('/deposit');
            } else {
              _showBankRequiredDialog(context);
            }
          }
          if (index == 3) context.push('/profile');
        },
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(settingsNotifierProvider.notifier).fetchSettings();
          await ref.read(transactionsNotifierProvider.notifier).fetchDashboard();
          await ref.read(bankDetailsNotifierProvider.notifier).fetchBankDetails();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Text(
                'Hello, ${user?.name ?? "Merchant"} 👋',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textPrim,
                ),
              ),
              const SizedBox(height: 20),

              // Live USDT buy-rate Display Card
              _buildLiveRateCard(context, rateSettings, isDark, cardClr, borderClr, textSec),
              const SizedBox(height: 20),

              // Action button row
              _buildSellActionCard(context, isBankComplete, isDark),
              const SizedBox(height: 28),

              // Trade Statistics Section
              Text(
                'Your OTC Stats',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrim,
                ),
              ),
              const SizedBox(height: 12),
              _buildStatsGrid(txState, cardClr, borderClr, textPrim, textSec),
              const SizedBox(height: 28),

              // Completeness Checklists
              Text(
                'Configuration Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrim,
                ),
              ),
              const SizedBox(height: 12),
              _buildConfigChecklist(context, isBankComplete, cardClr, borderClr, textPrim, textSec),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveRateCard(
    BuildContext context, 
    SettingsData rateSettings, 
    bool isDark, 
    Color cardClr, 
    Color borderClr, 
    Color textSec
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] 
              : [Colors.white, const Color(0xFFF1F5F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderClr, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withOpacity(isDark ? 0.08 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676),
                      blurRadius: isDark ? 8 : 4,
                      spreadRadius: isDark ? 2 : 1,
                    )
                  ]
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'LIVE USDT BUY RATE',
                style: TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatIndianCurrency(rateSettings.exchangeRate),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '1 USDT = ${_formatIndianCurrency(rateSettings.exchangeRate)} INR',
            style: TextStyle(
              color: textSec,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showBankRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bank Details Required'),
          content: const Text(
            'To sell USDT and receive INR payouts, you must first configure your bank account or UPI ID details.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/bank-details');
              },
              child: const Text('Setup Bank'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSellActionCard(BuildContext context, bool isBankComplete, bool isDark) {
    return InkWell(
      onTap: () {
        if (isBankComplete) {
          context.push('/deposit');
        } else {
          _showBankRequiredDialog(context);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFE6F4EA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFFCEEAD6),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isDark ? const Color(0xFF10B981) : const Color(0xFF0F9D58),
              child: const Icon(Icons.trending_up, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sell USDT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Deposit USDT to get fast INR payout to your bank',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5F6368),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
    TransactionsState txState, 
    Color cardClr, 
    Color borderClr, 
    Color textPrim, 
    Color textSec
  ) {
    final completedCount = txState.transactions.where((tx) => tx.status == 'paid' || tx.payout?.status == 'paid').length;
    final pendingCount = txState.transactions.where((tx) => tx.status == 'pending' || tx.status == 'confirmed' || tx.status == 'verified').length;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Total USDT Sold', '${txState.totalUsdtSold.toStringAsFixed(2)} USDT', cardClr, borderClr, textPrim, textSec),
        _buildStatCard('INR Received', _formatIndianCurrency(txState.totalInrReceived), cardClr, borderClr, textPrim, textSec),
        _buildStatCard('Completed Trades', completedCount.toString(), cardClr, borderClr, textPrim, textSec),
        _buildStatCard('Pending Trades', pendingCount.toString(), cardClr, borderClr, textPrim, textSec),
      ],
    );
  }

  Widget _buildStatCard(
    String label, 
    String value, 
    Color cardClr, 
    Color borderClr, 
    Color textPrim, 
    Color textSec
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardClr,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderClr),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textSec,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrim,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigChecklist(
    BuildContext context, 
    bool isBankComplete, 
    Color cardClr, 
    Color borderClr, 
    Color textPrim, 
    Color textSec
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardClr,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderClr),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildChecklistItem(
            title: 'Setup Bank Details',
            subtitle: 'Required for INR bank payouts',
            isComplete: isBankComplete,
            onTap: () => context.push('/bank-details'),
            textPrim: textPrim,
            textSec: textSec,
          ),
          const Divider(height: 24),
          _buildChecklistItem(
            title: 'Verify Account Status',
            subtitle: 'Active & ready for OTC trades',
            isComplete: true,
            onTap: () {},
            textPrim: textPrim,
            textSec: textSec,
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem({
    required String title,
    required String subtitle,
    required bool isComplete,
    required VoidCallback onTap,
    required Color textPrim,
    required Color textSec,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isComplete ? const Color(0xFF00E676) : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textPrim,
                    decoration: isComplete ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSec,
                  ),
                ),
              ],
            ),
          ),
          if (!isComplete)
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
