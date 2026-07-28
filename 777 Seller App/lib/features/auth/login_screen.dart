import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitPhone() async {
    debugPrint(
      'Submit Phone called. Form valid: ${_formKey.currentState!.validate()}',
    );
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    debugPrint('Sending OTP for phone: $phone');

    final success = await ref.read(authProvider.notifier).sendOtp(phone);
    debugPrint('Send OTP success: $success, mounted: $mounted');
    if (success && mounted) {
      debugPrint('Navigating to /otp');
      context.push('/otp');
    }
  }

  @override
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Center(
                child: Image.asset(
                  'assets/777logo.png',
                  width: 100,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 64,
                    color: activeGreen,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Enter Mobile Number',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrim,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We will send a 6-digit OTP code to verify your mobile number',
                style: TextStyle(fontSize: 14, color: textSec),
              ),
              const SizedBox(height: 32),

              // Phone Input Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                style: TextStyle(color: textPrim),
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  labelStyle: TextStyle(color: textSec),
                  hintText: 'Enter 10-digit number',
                  hintStyle: TextStyle(color: textSec.withOpacity(0.7)),
                  prefixText: '+91 ',
                  prefixStyle: TextStyle(
                    color: textPrim,
                    fontWeight: FontWeight.bold,
                  ),
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter mobile number';
                  }
                  if (value.length != 10 ||
                      !RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'Please enter a valid 10-digit mobile number';
                  }
                  return null;
                },
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
                  onPressed: authState.loading ? null : _submitPhone,
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
                      : const Text('Get OTP'),
                ),
              ),
              const SizedBox(height: 48),
              Center(
                child: Text(
                  'By continuing, you agree to our Terms & Conditions',
                  style: TextStyle(fontSize: 11, color: textSec),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
