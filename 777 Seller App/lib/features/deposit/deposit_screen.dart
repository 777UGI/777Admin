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
  int _secondsRemaining = 900; 
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
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _isRateExpired = true);
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
      _depositAddress = rateSettings.wallets[_selectedNetwork] ?? _fallbackAddresses[_selectedNetwork] ?? 'Error';
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
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(value);
  }

  Future<void> _submitDepositProof() async {
    if (!_proofFormKey.currentState!.validate()) return;
    if (_isRateExpired) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rate lock expired. Please refresh.')));
      return;
    }
    final amount = double.parse(_amountController.text);
    final result = await ref.read(transactionsNotifierProvider.notifier).createDeposit(
          amountUsdt: amount,
          network: _selectedNetwork,
          txHash: _txHashController.text.trim(),
        );
    if (result != null && mounted) {
      context.replace('/tracker/${result.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txState = ref.watch(transactionsNotifierProvider);

    return AppScaffold(
      appBar: AppBar(title: const Text('Sell USDT')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_rateLocked) ...[
              _buildStepTitle(context, '1. Set Amount', 'Choose how much USDT you want to sell'),
              const SizedBox(height: 16),
              Form(
                key: _amountFormKey,
                child: DropdownButtonFormField<double>(
                  value: double.tryParse(_amountController.text) ?? 500.0,
                  decoration: const InputDecoration(labelText: 'Amount', suffixText: 'USDT'),
                  items: [500.0, 1000.0, 2500.0, 5000.0, 10000.0].map((e) => DropdownMenuItem(value: e, child: Text(e.toStringAsFixed(0)))).toList(),
                  onChanged: (val) => val != null ? setState(() => _amountController.text = val.toStringAsFixed(0)) : null,
                ),
              ),
              const SizedBox(height: 24),
              _buildStepTitle(context, '2. Settlement Plan', 'Select your preferred payout duration'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSettlementDuration,
                decoration: const InputDecoration(labelText: 'Payout Speed'),
                items: const [
                  DropdownMenuItem(value: '2 Days', child: Text('2 Days (Express - High Risk)')),
                  DropdownMenuItem(value: '3 Days', child: Text('3 Days (Standard - Safe)')),
                  DropdownMenuItem(value: '4 Days', child: Text('4 Days (Secure - Recommended)')),
                ],
                onChanged: (val) => val != null ? setState(() => _selectedSettlementDuration = val) : null,
              ),
              if (_selectedSettlementDuration == '2 Days') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: theme.colorScheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(Icons.warning_rounded, color: theme.colorScheme.error, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Note: Express transfers carry higher risk of bank scrutiny.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _buildStepTitle(context, '3. Network', 'Choose blockchain network for deposit'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: ['TRC20', 'BEP20', 'ERC20', 'SOL'].map((net) => ChoiceChip(
                  label: Text(net),
                  selected: _selectedNetwork == net,
                  onSelected: (val) => val ? setState(() => _selectedNetwork = net) : null,
                )).toList(),
              ),
              const SizedBox(height: 40),
              ElevatedButton(onPressed: _lockRateAndAddress, child: const Text('LOCK RATE & CONTINUE')),
            ] else ...[
              _buildRateLockCard(context),
              const SizedBox(height: 24),
              _buildDepositInfoCard(context),
              const SizedBox(height: 32),
              _buildStepTitle(context, 'Submit Proof', 'Paste your transaction hash (TXID)'),
              const SizedBox(height: 16),
              Form(
                key: _proofFormKey,
                child: TextFormField(
                  controller: _txHashController,
                  decoration: const InputDecoration(labelText: 'TXID / Hash', hintText: 'Enter transaction hash'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : (v.length < 16 ? 'Invalid hash' : null),
                ),
              ),
              const SizedBox(height: 24),
              if (txState.error != null) Text(txState.error!, style: TextStyle(color: theme.colorScheme.error)),
              ElevatedButton(onPressed: txState.loading ? null : _submitDepositProof, child: txState.loading ? const CircularProgressIndicator(color: Colors.white) : const Text('SUBMIT PROOF')),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => setState(() => _rateLocked = false), child: const Text('CANCEL')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepTitle(BuildContext context, String title, String subtitle) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: theme.textTheme.titleMedium),
      Text(subtitle, style: theme.textTheme.bodySmall),
    ]);
  }

  Widget _buildRateLockCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Locked Rate', style: theme.textTheme.bodyMedium),
              Text(_formatIndianCurrency(_lockedRate), style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('You will receive', style: theme.textTheme.bodyMedium),
              Text(_formatIndianCurrency(_lockedInrAmount), style: theme.textTheme.titleLarge),
            ]),
            const Divider(height: 32),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.timer_outlined, size: 18, color: _isRateExpired ? theme.colorScheme.error : theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(_isRateExpired ? 'Rate Expired' : 'Expires in ${_formatTimer(_secondsRemaining)}', style: theme.textTheme.labelLarge?.copyWith(color: _isRateExpired ? theme.colorScheme.error : theme.colorScheme.primary)),
              if (_isRateExpired) IconButton(onPressed: _refreshRate, icon: const Icon(Icons.refresh_rounded, size: 20)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildDepositInfoCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Send exactly ${_amountController.text} USDT ($_selectedNetwork)', style: theme.textTheme.titleSmall),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: QrImageView(data: _depositAddress, size: 160, version: QrVersions.auto),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _depositAddress));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address copied')));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(child: Text(_depositAddress, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    const Icon(Icons.copy_rounded, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Only send USDT via $_selectedNetwork. Other assets will be lost.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

