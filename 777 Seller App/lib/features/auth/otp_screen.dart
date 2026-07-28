import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submitOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final otp = _otpController.text.trim();
    final authNotifier = ref.read(authProvider.notifier);

    final success = await authNotifier.verifyOtp(otp);
    if (success && mounted) {
      final state = ref.read(authProvider);
      if (state.user != null) {
        context.go('/home');
      } else {
        context.go('/signup');
      }
    }
  }

  Future<void> _resendOtp() async {
    final phone = ref.read(authProvider).phoneNumber;
    if (phone != null) {
      final success = await ref.read(authProvider.notifier).sendOtp(phone);
      if (success) {
        _startTimer();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP resent successfully. (Use 123456)'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgClr = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8F9FA);
    final textPrim = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final textSec = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final activeGreen = isDark ? const Color(0xFF00E676) : const Color(0xFF0F9D58);

    return AppScaffold(
      backgroundColor: bgClr,
      appBar: AppBar(
        title: const Text('OTP Verification'),
        backgroundColor: bgClr,
        iconTheme: IconThemeData(color: textPrim),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Verify Mobile Number',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrim,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit OTP code sent to +91 ${authState.phoneNumber ?? ""}',
                style: TextStyle(fontSize: 14, color: textSec),
              ),
              const SizedBox(height: 32),

              // OTP Input
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: TextStyle(
                  fontSize: 18,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                  color: textPrim,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'OTP Code',
                  labelStyle: TextStyle(color: textSec),
                  hintText: '000000',
                  counterText: '',
                  hintStyle: const TextStyle(
                    fontSize: 18,
                    letterSpacing: 8,
                    color: Color(0xFF475569),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter OTP';
                  }
                  if (value.length != 6 ||
                      !RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'Please enter valid 6-digit OTP';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Timer and Resend Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _canResend
                        ? 'Didn\'t receive code?'
                        : 'Resend code in ${_secondsRemaining}s',
                    style: TextStyle(
                      fontSize: 13,
                      color: _canResend ? textSec : textSec.withOpacity(0.7),
                    ),
                  ),
                  TextButton(
                    onPressed: _canResend ? _resendOtp : null,
                    child: Text(
                      'Resend OTP',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _canResend
                            ? activeGreen
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (authState.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    authState.error!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ),

              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: activeGreen.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: authState.loading ? null : _submitOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeGreen,
                    foregroundColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: authState.loading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? const Color(0xFF0B0F19) : Colors.white,
                            ),
                          ),
                        )
                      : const Text('Verify & Proceed'),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Default verification code is 123456',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSec,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
