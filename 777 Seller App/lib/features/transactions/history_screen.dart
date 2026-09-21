import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/statement_generator.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../auth/auth_provider.dart';
import 'transactions_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _selectedStatusFilter = 'all';
  String _selectedDateFilter = 'all';

  List<TransactionModel> _applyFilters(List<TransactionModel> list) {
    var filtered = List<TransactionModel>.from(list);
    if (_selectedStatusFilter != 'all') {
      filtered = filtered.where((tx) => _selectedStatusFilter == 'paid' ? (tx.status == 'paid' || tx.payout?.status == 'paid') : tx.status.toLowerCase() == _selectedStatusFilter).toList();
    }
    if (_selectedDateFilter != 'all') {
      final now = DateTime.now();
      final cutOff = _selectedDateFilter == 'week' ? now.subtract(const Duration(days: 7)) : now.subtract(const Duration(days: 30));
      filtered = filtered.where((tx) => (DateTime.tryParse(tx.createdAt) ?? now).isAfter(cutOff)).toList();
    }
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  String _formatIndianCurrency(double value) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(value);
  }

  Future<void> _openBlockExplorer(BuildContext context, TransactionModel tx) async {
    final url = Uri.parse((tx.network == 'TRC20' ? 'https://tronscan.org/#/transaction/' : 'https://bscscan.com/tx/') + tx.txHash);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        Clipboard.setData(ClipboardData(text: tx.txHash));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('TXID copied to clipboard.')));
      }
    } catch (e) {
      Clipboard.setData(ClipboardData(text: tx.txHash));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txState = ref.watch(transactionsNotifierProvider);
    final filteredList = _applyFilters(txState.transactions);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Trade History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined),
            onPressed: () async {
              final user = ref.read(authProvider).user;
              if (user != null && filteredList.isNotEmpty) {
                await StatementGenerator.generateAndShare(user: user, transactions: filteredList);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(transactionsNotifierProvider.notifier).fetchDashboard(),
              child: filteredList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded, size: 64, color: theme.colorScheme.outline),
                          const SizedBox(height: 16),
                          Text('No trades found', style: theme.textTheme.titleMedium),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) => _buildTradeCard(context, filteredList[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeCard(BuildContext context, TransactionModel tx) {
    final theme = Theme.of(context);
    final date = DateTime.tryParse(tx.createdAt)?.toLocal() ?? DateTime.now();
    final isPaid = tx.payout?.status == 'paid' || tx.status == 'paid';
    final isApproved = isPaid || tx.status == 'verified' || tx.status == 'approved' || tx.status == 'confirmed';
    final statusText = isApproved ? 'Approved' : 'Pending';
    final statusColor = isApproved ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2))),
      ),
      child: InkWell(
        onTap: () => _showReceiptModal(context, tx),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('USDT Sent ($statusText)', style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '${tx.amountUsdt}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM, hh:mm a').format(date),
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('INR Received', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                    const SizedBox(height: 4),
                    Text(
                      _formatIndianCurrency(tx.amountUsdt * tx.rateLockedInr),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReceiptModal(BuildContext context, TransactionModel tx) {
    final theme = Theme.of(context);
    final isPaid = tx.payout?.status == 'paid' || tx.status == 'paid';
    final color = isPaid ? Colors.green : (tx.status == 'rejected' ? Colors.redAccent : Colors.orange);
    final icon = isPaid ? Icons.check_circle_rounded : (tx.status == 'rejected' ? Icons.cancel_rounded : Icons.pending_actions_rounded);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _formatIndianCurrency(tx.amountUsdt * tx.rateLockedInr),
                style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
              ),
            ),
            Center(
              child: Text(
                isPaid ? 'Payment Successful' : 'Processing Payment',
                style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildRow('Exchange Rate', '₹${tx.rateLockedInr.toStringAsFixed(2)} / USDT'),
                  const Divider(height: 24),
                  _buildRow('Tokens Sent', '${tx.amountUsdt} USDT'),
                  const Divider(height: 24),
                  _buildRow('Network', tx.network),
                  if (tx.payout?.payoutReference != null) ...[
                    const Divider(height: 24),
                    _buildRow('Bank UTR', tx.payout!.payoutReference!, isBold: true),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Transaction Hash', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
              child: SelectableText(tx.txHash, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _openBlockExplorer(context, tx), 
              icon: const Icon(Icons.explore_rounded),
              label: const Text('View on Explorer'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }
}

