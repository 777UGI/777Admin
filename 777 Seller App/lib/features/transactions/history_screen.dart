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
  String _selectedStatusFilter =
      'all'; // all, pending, verified, paid, rejected
  String _selectedDateFilter = 'all'; // all, week, month

  List<TransactionModel> _applyFilters(List<TransactionModel> list) {
    var filtered = List<TransactionModel>.from(list);

    // Apply status filter
    if (_selectedStatusFilter != 'all') {
      filtered = filtered.where((tx) {
        if (_selectedStatusFilter == 'paid') {
          return tx.status == 'paid' || tx.payout?.status == 'paid';
        }
        return tx.status.toLowerCase() == _selectedStatusFilter;
      }).toList();
    }

    // Apply date filter
    if (_selectedDateFilter != 'all') {
      final now = DateTime.now();
      DateTime cutOff;
      if (_selectedDateFilter == 'week') {
        cutOff = now.subtract(const Duration(days: 7));
      } else {
        cutOff = now.subtract(const Duration(days: 30));
      }
      filtered = filtered.where((tx) {
        final txDate = DateTime.tryParse(tx.createdAt) ?? now;
        return txDate.isAfter(cutOff);
      }).toList();
    }

    // Sort by date descending
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  String _formatIndianCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  Future<void> _openBlockExplorer(TransactionModel tx) async {
    final baseUrl = tx.network == 'TRC20'
        ? 'https://tronscan.org/#/transaction/'
        : 'https://bscscan.com/tx/';
    final url = Uri.parse('$baseUrl${tx.txHash}');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        Clipboard.setData(ClipboardData(text: tx.txHash));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not open block explorer. TXID copied to clipboard.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      Clipboard.setData(ClipboardData(text: tx.txHash));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('TXID copied to clipboard.')),
        );
      }
    }
  }

  void _downloadStatement(List<TransactionModel> txList) async {
    final user = ref.read(authProvider).user;
    if (user != null && txList.isNotEmpty) {
      await StatementGenerator.generateAndShare(
        user: user,
        transactions: txList,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No trades available to generate statement.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionsNotifierProvider);
    final filteredList = _applyFilters(txState.transactions);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgClr = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8F9FA);
    final cardClr = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderClr = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrim = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final textSec = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return AppScaffold(
      backgroundColor: bgClr,
      appBar: AppBar(
        title: const Text('Trades Ledger'),
        backgroundColor: bgClr,
        iconTheme: IconThemeData(color: textPrim),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download Statement',
            onPressed: () => _downloadStatement(filteredList),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Ribbon
          Container(
            color: cardClr,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // Status Filter
                Row(
                  children: [
                    Text(
                      'Status: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textSec,
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              'all',
                              'All',
                              _selectedStatusFilter,
                              (v) => setState(() => _selectedStatusFilter = v),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'pending',
                              'Pending',
                              _selectedStatusFilter,
                              (v) => setState(() => _selectedStatusFilter = v),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'verified',
                              'Verified',
                              _selectedStatusFilter,
                              (v) => setState(() => _selectedStatusFilter = v),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'paid',
                              'Paid',
                              _selectedStatusFilter,
                              (v) => setState(() => _selectedStatusFilter = v),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'rejected',
                              'Rejected',
                              _selectedStatusFilter,
                              (v) => setState(() => _selectedStatusFilter = v),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Date Filter
                Row(
                  children: [
                    Text(
                      'Range: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textSec,
                      ),
                    ),
                    _buildFilterChip(
                      'all',
                      'All Time',
                      _selectedDateFilter,
                      (v) => setState(() => _selectedDateFilter = v),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'week',
                      'Last 7 Days',
                      _selectedDateFilter,
                      (v) => setState(() => _selectedDateFilter = v),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'month',
                      'Last 30 Days',
                      _selectedDateFilter,
                      (v) => setState(() => _selectedDateFilter = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderClr),

          // Ledger Trades list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(transactionsNotifierProvider.notifier)
                    .fetchDashboard();
              },
              child: filteredList.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 100),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_toggle_off,
                                size: 64,
                                color: textSec.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No trades logged matching filters.',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textSec,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final tx = filteredList[index];
                        return _buildTradeCard(context, tx);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String value,
    String label,
    String groupValue,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = value == groupValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrim = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final activeGreen = isDark ? const Color(0xFF00E676) : const Color(0xFF0F9D58);
    final alertBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F3F4);

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isSelected ? Colors.white : textPrim,
        ),
      ),
      selected: isSelected,
      onSelected: (val) {
        if (val) onSelected(value);
      },
      selectedColor: activeGreen,
      backgroundColor: alertBg,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildTradeCard(BuildContext context, TransactionModel tx) {
    final date = DateTime.tryParse(tx.createdAt)?.toLocal() ?? DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrim = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final textSec = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final activeGreen = isDark ? const Color(0xFF00E676) : const Color(0xFF0F9D58);
    final borderClr = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final isPayoutPaid = tx.payout?.status == 'paid';
    Color statusColor = Colors.orange;
    String statusLabel = 'PENDING';
    if (tx.status == 'verified' && !isPayoutPaid) {
      statusColor = Colors.blue;
      statusLabel = 'VERIFIED';
    } else if (tx.status == 'rejected') {
      statusColor = Colors.red;
      statusLabel = 'REJECTED';
    } else if (isPayoutPaid || tx.status == 'paid') {
      statusColor = activeGreen;
      statusLabel = 'PAID';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showReceiptModal(context, tx),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tx.amountUsdt} USDT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textPrim,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSec,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatIndianCurrency(tx.amountUsdt * tx.rateLockedInr),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textPrim,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Divider(height: 20, color: borderClr),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Network: ${tx.network}',
                    style: TextStyle(fontSize: 11, color: textSec),
                  ),
                  InkWell(
                    onTap: () => _openBlockExplorer(tx),
                    child: const Row(
                      children: [
                        Text(
                          'Block Explorer',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.launch, size: 12, color: Colors.blue),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReceiptModal(BuildContext context, TransactionModel tx) {
    final isPayoutPaid = tx.payout?.status == 'paid';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeGreen = isDark ? const Color(0xFF00E676) : const Color(0xFF0F9D58);
    final textSec = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trade Receipt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModalRow('Network:', tx.network),
            _buildModalRow('USDT Sent:', '${tx.amountUsdt} USDT'),
            _buildModalRow(
              'Locked Rate:',
              '₹${tx.rateLockedInr.toStringAsFixed(2)}',
            ),
            _buildModalRow(
              'Total INR payout:',
              _formatIndianCurrency(tx.amountUsdt * tx.rateLockedInr),
            ),
            _buildModalRow('Deposit Status:', tx.status.toUpperCase()),
            const Divider(height: 20),
            Text(
              'TXID Hash:',
              style: TextStyle(fontSize: 12, color: textSec),
            ),
            const SizedBox(height: 4),
            SelectableText(
              tx.txHash,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.blue,
              ),
            ),
            if (isPayoutPaid) ...[
              const Divider(height: 20),
              Text(
                'Payout Info:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: activeGreen,
                ),
              ),
              const SizedBox(height: 4),
              _buildModalRow(
                'UTR Reference:',
                tx.payout?.payoutReference ?? 'Pending UTR',
              ),
              _buildModalRow('Method:', tx.payout?.payoutMethod ?? 'UPI'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => _openBlockExplorer(tx),
            child: const Text('Verify on Chain'),
          ),
        ],
      ),
    );
  }

  Widget _buildModalRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrim = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final textSec = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: textSec)),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrim),
          ),
        ],
      ),
    );
  }
}
