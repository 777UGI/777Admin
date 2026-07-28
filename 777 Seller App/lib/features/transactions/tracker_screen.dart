import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'transactions_provider.dart';

class TrackerScreen extends ConsumerStatefulWidget {
  final String depositId;

  const TrackerScreen({super.key, required this.depositId});

  @override
  ConsumerState<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends ConsumerState<TrackerScreen> {
  Timer? _pollingTimer;
  int _simulatedConfirmations = 4;
  late final Timer _simulatedTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();

    // Simulate incremental blockchain confirmations
    _simulatedTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && _simulatedConfirmations < 20) {
        setState(() {
          _simulatedConfirmations++;
        });
      }
    });
  }

  void _startPolling() {
    // Poll the dashboard endpoints every 10 seconds while open
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await ref.read(transactionsNotifierProvider.notifier).fetchDashboard();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _simulatedTimer.cancel();
    super.dispose();
  }

  String _formatIndianCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionsNotifierProvider);

    // Find the current active transaction matching depositId
    final TransactionModel activeTx = txState.transactions.firstWhere(
      (tx) => tx.id == widget.depositId,
      orElse: () => txState.transactions.isNotEmpty
          ? txState.transactions.first
          : TransactionModel(
              id: widget.depositId,
              userId: '',
              txHash: '0xHashLoading...',
              amountUsdt: 0.0,
              network: 'TRC20',
              rateLockedInr: 88.5,
              status: 'pending',
              createdAt: DateTime.now().toIso8601String(),
            ),
    );

    final String status = activeTx.status;
    final isPayoutPaid = activeTx.payout?.status == 'paid';

    // Determine active steps
    // Steps: 0: Awaiting, 1: Confirming, 2: Verified, 3: Processing, 4: Paid
    int currentStep = 0;
    if (status == 'pending') {
      currentStep = 1;
    } else if (status == 'confirmed') {
      currentStep = 2;
    } else if (status == 'verified') {
      currentStep = 3;
    } else if (status == 'paid' || isPayoutPaid) {
      currentStep = 4;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgClr = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8F9FA);
    final cardClr = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderClr = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrim = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final textSec = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final activeGreen = isDark ? const Color(0xFF00E676) : const Color(0xFF0F9D58);

    return AppScaffold(
      backgroundColor: bgClr,
      appBar: AppBar(
        title: const Text('Transaction Tracker'),
        backgroundColor: bgClr,
        iconTheme: IconThemeData(color: textPrim),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(transactionsNotifierProvider.notifier)
              .fetchDashboard();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Receipt Overview Card
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
                    Text(
                      'Expected INR Payout',
                      style: TextStyle(color: textSec, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatIndianCurrency(
                        activeTx.amountUsdt * activeTx.rateLockedInr,
                      ),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: activeGreen,
                      ),
                    ),
                    Divider(height: 32, color: borderClr),
                    _buildDetailRow(
                      'Amount Sold:',
                      '${activeTx.amountUsdt} USDT (${activeTx.network})',
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Locked Rate:',
                      '₹${activeTx.rateLockedInr.toStringAsFixed(2)} / USDT',
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'TXID Hash:',
                      activeTx.txHash,
                      isHash: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Processing Timeline',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrim,
                ),
              ),
              const SizedBox(height: 20),

              // Vertical Stepper Timeline
              _buildTimelineStep(
                index: 0,
                title: 'Awaiting Deposit Detected',
                subtitle: 'Sellers submitted transaction receipt proof.',
                isActive: currentStep >= 0,
                isCompleted: currentStep > 0,
              ),
              _buildTimelineStep(
                index: 1,
                title: 'Confirming on Blockchain',
                subtitle: currentStep == 1
                    ? 'Confirmations: $_simulatedConfirmations/20...'
                    : (currentStep > 1
                          ? 'Confirmed on chain ✓'
                          : 'Awaiting nodes...'),
                isActive: currentStep >= 1,
                isCompleted: currentStep > 1,
              ),
              _buildTimelineStep(
                index: 2,
                title: 'USDT Received & Verified',
                subtitle: 'Platform compliance desk verified the funds.',
                isActive: currentStep >= 2,
                isCompleted: currentStep > 2,
              ),
              _buildTimelineStep(
                index: 3,
                title: 'INR Payout Processing',
                subtitle: 'Platform banking node is sending IMPS/UPI transfer.',
                isActive: currentStep >= 3,
                isCompleted: currentStep > 3,
              ),
              _buildTimelineStep(
                index: 4,
                title: 'Paid (Complete)',
                subtitle: isPayoutPaid
                    ? 'INR Sent! UTR: ${activeTx.payout?.payoutReference ?? "MOCK_UTR_REF"}'
                    : 'Awaiting bank reference code...',
                isActive: currentStep >= 4,
                isCompleted: currentStep >= 4,
                isLast: true,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHash = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrim = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final textSec = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: textSec, fontSize: 13)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: isHash ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              fontFamily: isHash ? 'monospace' : null,
              color: isHash ? Colors.blue : textPrim,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required int index,
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isCompleted,
    bool isLast = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderClr = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrim = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final textSec = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final activeGreen = isDark ? const Color(0xFF00E676) : const Color(0xFF0F9D58);

    Color iconColor = isDark ? const Color(0xFF334155) : Colors.grey[300]!;
    Widget iconChild = Text(
      '${index + 1}',
      style: const TextStyle(
        fontSize: 12,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );

    if (isCompleted) {
      iconColor = activeGreen;
      iconChild = const Icon(Icons.check, size: 14, color: Colors.white);
    } else if (isActive) {
      iconColor = Colors.blue;
      iconChild = const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(Colors.white),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: iconChild,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? activeGreen : borderClr,
                  ),
                ),
            ],
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
                    color: isActive ? textPrim : textSec,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: textSec),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
