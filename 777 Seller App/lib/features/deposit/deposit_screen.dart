import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../home/rate_provider.dart';
import '../transactions/transactions_provider.dart';

class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  final _amountFormKey = GlobalKey<FormState>();
  final _proofFormKey = GlobalKey<FormState>();
  
  final _amountController = TextEditingController(text: '500');
  final _txHashController = TextEditingController();

  static const Map<String, String> _fallbackAddresses = {
    'TRC20': 'TY1H4HqB7777xYzQrT22WpW1xTRX5YVzQp',
    'BEP20': '0x742d35Cc6634C0532925a3b844Bc454e4438f44e',
    'ERC20': '0x3f5CE5FBFe3E9af3971dD833D26bA9b5C936f0bE',
    'SOL': 'HN7cE25AecC5i4yYwF5E1fPz43x8z9A5bBcDdEeFfGgH',
  };

  String _selectedNetwork = 'TRC20';
  String _selectedSettlementDuration = '3 Days';
  bool _rateLocked = false;
  double _lockedRate = 88.5;
  double _lockedInrAmount = 0.0;
  String _depositAddress = '';

  Timer? _countdownTimer;
  int _secondsRemaining = 900; // 15 minutes
  bool _isRateExpired = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _amountController.dispose();
    _txHashController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _secondsRemaining = 900;
      _isRateExpired = false;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _isRateExpired = true;
        });
        _countdownTimer?.cancel();
      }
    });
  }

  void _lockRateAndAddress() {
    if (!_amountFormKey.currentState!.validate()) return;

    final rateSettings = ref.read(settingsNotifierProvider);
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    setState(() {
      _lockedRate = rateSettings.exchangeRate;
      _lockedInrAmount = amount * _lockedRate;
      _depositAddress = rateSettings.wallets[_selectedNetwork] ?? _fallbackAddresses[_selectedNetwork] ?? 'Address Loading Error';
      _rateLocked = true;
    });
    _startCountdown();
  }

  void _refreshRate() {
    final rateSettings = ref.read(settingsNotifierProvider);
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    setState(() {
      _lockedRate = rateSettings.exchangeRate;
      _lockedInrAmount = amount * _lockedRate;
    });
    _startCountdown();
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatIndianCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  Future<void> _submitDepositProof() async {
    if (!_proofFormKey.currentState!.validate()) return;
    if (_isRateExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rate lock has expired. Please refresh the rate first.')),
      );
      return;
    }

    final amount = double.parse(_amountController.text);
    final txHash = _txHashController.text.trim();

    final result = await ref.read(transactionsNotifierProvider.notifier).createDeposit(
          amountUsdt: amount,
          network: _selectedNetwork,
          txHash: txHash,
        );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deposit proof submitted successfully.')),
      );
      // Navigate to tracking screen for this deposit
      context.replace('/tracker/${result.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgClr = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8F9FA);
    final cardClr = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderClr = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrim = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final textSec = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final activeGreen = isDark ? const Color(0xFF00E676) : const Color(0xFF0F9D58);
    final warningBg = isDark ? const Color(0xFFEF4444).withOpacity(0.15) : const Color(0xFFFFF0F0);
    final alertBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F3F4);

    return AppScaffold(
      backgroundColor: bgClr,
      appBar: AppBar(
        title: const Text('Sell / Deposit USDT'),
        backgroundColor: bgClr,
        iconTheme: IconThemeData(color: textPrim),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_rateLocked) ...[
              // Step 1: Input Amount and Select Network
              Form(
                key: _amountFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How much USDT would you like to sell?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrim),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<double>(
                      initialValue: double.tryParse(_amountController.text) ?? 500.0,
                      dropdownColor: cardClr,
                      style: TextStyle(color: textPrim, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'USDT Amount',
                        labelStyle: TextStyle(color: textSec),
                        suffixText: 'USDT',
                      ),
                      items: const [
                        DropdownMenuItem(value: 500.0, child: Text('500')),
                        DropdownMenuItem(value: 750.0, child: Text('750')),
                        DropdownMenuItem(value: 1000.0, child: Text('1000')),
                        DropdownMenuItem(value: 1250.0, child: Text('1250')),
                        DropdownMenuItem(value: 1500.0, child: Text('1500')),
                        DropdownMenuItem(value: 2000.0, child: Text('2000')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _amountController.text = val.toStringAsFixed(0);
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select USDT amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Duration of Complete Settlement of INR',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrim),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSettlementDuration,
                      dropdownColor: cardClr,
                      style: TextStyle(color: textPrim, fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'Settlement Duration',
                        labelStyle: TextStyle(color: textSec),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: '2 Days',
                          child: Text(
                            '2 Days (Risky - Fast Transfer)',
                            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                          ),
                        ),
                        DropdownMenuItem(
                          value: '3 Days',
                          child: Text('3 Days (Safe & Recommended)'),
                        ),
                        DropdownMenuItem(
                          value: '4 Days',
                          child: Text('4 Days (Extra Secure)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedSettlementDuration = val;
                          });
                        }
                      },
                    ),
                    if (_selectedSettlementDuration == '2 Days') ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Risky: Rapid large amount transfers can flag your account and cause a bank freeze. We recommend 3 Days or 4 Days.',
                                style: TextStyle(
                                  color: Colors.redAccent.withOpacity(0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Choose Blockchain Network',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrim),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ChoiceChip(
                          label: Text(
                            'TRC20 (TRON)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _selectedNetwork == 'TRC20' ? activeGreen : textSec,
                            ),
                          ),
                          selected: _selectedNetwork == 'TRC20',
                          onSelected: (val) {
                            if (val) setState(() => _selectedNetwork = 'TRC20');
                          },
                        ),
                        ChoiceChip(
                          label: Text(
                            'BEP20 (BSC)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _selectedNetwork == 'BEP20' ? activeGreen : textSec,
                            ),
                          ),
                          selected: _selectedNetwork == 'BEP20',
                          onSelected: (val) {
                            if (val) setState(() => _selectedNetwork = 'BEP20');
                          },
                        ),
                        ChoiceChip(
                          label: Text(
                            'ERC20 (ETH)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _selectedNetwork == 'ERC20' ? activeGreen : textSec,
                            ),
                          ),
                          selected: _selectedNetwork == 'ERC20',
                          onSelected: (val) {
                            if (val) setState(() => _selectedNetwork = 'ERC20');
                          },
                        ),
                        ChoiceChip(
                          label: Text(
                            'SOL (Solana)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _selectedNetwork == 'SOL' ? activeGreen : textSec,
                            ),
                          ),
                          selected: _selectedNetwork == 'SOL',
                          onSelected: (val) {
                            if (val) setState(() => _selectedNetwork = 'SOL');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _lockRateAndAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeGreen,
                        foregroundColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
                      ),
                      child: const Text('Get Deposit Address & Lock Rate'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Step 2: Display Locked Rate, Address, QR Code, and Proof Submission
              Card(
                color: cardClr,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: borderClr),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Locked Buy-Rate:', style: TextStyle(color: textSec, fontSize: 13)),
                          Text(
                            _formatIndianCurrency(_lockedRate),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: activeGreen),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Expected INR Payout:', style: TextStyle(color: textSec, fontSize: 13)),
                          Text(
                            _formatIndianCurrency(_lockedInrAmount),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: activeGreen),
                          ),
                        ],
                      ),
                      Divider(height: 24, color: borderClr),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isRateExpired ? Icons.timer_off : Icons.timer,
                            color: _isRateExpired ? Colors.red : activeGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isRateExpired
                                ? 'Rate Lock Expired!'
                                : 'Rate Locked: ${_formatTimer(_secondsRemaining)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _isRateExpired ? Colors.red : activeGreen,
                            ),
                          ),
                          if (_isRateExpired) ...[
                            const SizedBox(width: 12),
                            IconButton(
                              icon: Icon(Icons.refresh, color: activeGreen),
                              onPressed: _refreshRate,
                              tooltip: 'Refresh Locked Rate',
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Deposit Target Card
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardClr,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderClr),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Send Exactly ${_amountController.text} USDT via $_selectedNetwork',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrim),
                      ),
                      const SizedBox(height: 16),
                      
                      // QR Code
                      QrImageView(
                        data: _depositAddress,
                        version: QrVersions.auto,
                        size: 160.0,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 16),

                      // Copyable Address Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: alertBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _depositAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: textPrim),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: _depositAddress));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Address copied to clipboard.')),
                                );
                              },
                              child: Icon(Icons.copy, size: 20, color: textSec),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Warnings
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: warningBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '⚠ WARNING: Only send USDT via the $_selectedNetwork network to this address. Sending on other chains will result in permanent loss.',
                          style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Transaction Proof Form
              Form(
                key: _proofFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submit Deposit Proof',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrim),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Paste the transaction hash / TXID from your crypto wallet below.',
                      style: TextStyle(fontSize: 13, color: textSec),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _txHashController,
                      style: TextStyle(color: textPrim),
                      decoration: InputDecoration(
                        labelText: 'Transaction ID / Hash (TXID)',
                        labelStyle: TextStyle(color: textSec),
                        hintText: 'e.g. 0x742d35Cc6634C...',
                        hintStyle: TextStyle(color: textSec.withOpacity(0.7)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Transaction hash is required';
                        }
                        if (value.trim().length < 16) {
                          return 'Enter a valid transaction hash';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    if (txState.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          txState.error!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),

                    ElevatedButton(
                      onPressed: txState.loading ? null : _submitDepositProof,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeGreen,
                        foregroundColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
                      ),
                      child: txState.loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text('Submit Trade Proof'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _rateLocked = false;
                        });
                        _countdownTimer?.cancel();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrim,
                        side: BorderSide(color: borderClr),
                      ),
                      child: const Text('Cancel Trade'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
