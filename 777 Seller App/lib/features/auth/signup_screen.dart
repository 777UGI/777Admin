import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _refCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final phone = ref.read(authProvider).phoneNumber;
    if (phone != null) {
      _phoneController.text = phone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _refCodeController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final referralCode = _refCodeController.text.trim().isEmpty
        ? null
        : _refCodeController.text.trim();

    final success = await ref
        .read(authProvider.notifier)
        .register(
          name: name,
          phone: phone,
          email: email,
          password: password,
          referralCode: referralCode,
        );

    if (success && mounted) {
      context.go('/home');
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
      appBar: AppBar(
        title: const Text('Complete Profile'),
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
              Text(
                'Create 777 Gateway Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrim,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please set up your profile credentials for phone +91 ${authState.phoneNumber ?? ""}',
                style: TextStyle(fontSize: 14, color: textSec),
              ),
              const SizedBox(height: 28),

              // Full Name
              TextFormField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                style: TextStyle(color: textPrim),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: TextStyle(color: textSec),
                  hintText: 'Enter your legal name (matches bank/PAN)',
                  hintStyle: TextStyle(color: textSec.withOpacity(0.7)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  if (value.trim().length < 3) {
                    return 'Name should be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Mobile Number
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
              const SizedBox(height: 16),

              // Email Address
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: textPrim),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: TextStyle(color: textSec),
                  hintText: 'Enter your email address',
                  hintStyle: TextStyle(color: textSec.withOpacity(0.7)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email address';
                  }
                  final emailRegex = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: TextStyle(color: textPrim),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: textSec),
                  hintText: 'Set a secure login password',
                  hintStyle: TextStyle(color: textSec.withOpacity(0.7)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please set a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Referral / Agent Code
              TextFormField(
                controller: _refCodeController,
                textCapitalization: TextCapitalization.characters,
                style: TextStyle(color: textPrim),
                decoration: InputDecoration(
                  labelText: 'Referral / Agent Code (Optional)',
                  labelStyle: TextStyle(color: textSec),
                  hintText: 'e.g. AGT_B37EC5',
                  hintStyle: TextStyle(color: textSec.withOpacity(0.7)),
                ),
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
                  onPressed: authState.loading ? null : _submitRegister,
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
                      : const Text('Complete Registration'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
