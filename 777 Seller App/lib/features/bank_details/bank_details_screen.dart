import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/storage/screen_security.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'bank_provider.dart';
import '../../core/constants/indian_geography.dart';

class BankDetailsScreen extends ConsumerStatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  ConsumerState<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends ConsumerState<BankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late TextEditingController _accountNumberController;
  late TextEditingController _confirmAccountNumberController;
  late TextEditingController _ifscController;
  late TextEditingController _holderNameController;
  late TextEditingController _upiIdController;
  late TextEditingController _addressController;
  late TextEditingController _districtController;
  late TextEditingController _stateController;
  late TextEditingController _hawalaTxHashController;
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  File? _hawalaTxScreenshotFile;
  Uint8List? _hawalaTxScreenshotBytes;
  String _bankSearchQuery = '';

  void _showSearchableBankBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgClr = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrim = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final textSec = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final inputBg = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF1F5F9);
    final borderClr = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgClr,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                // Filtered list
                final query = _bankSearchQuery.toLowerCase();
                final filteredBanks = _majorIndianBanks
                    .where((bank) => bank.toLowerCase().contains(query))
                    .toList();

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      // Grabber handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: borderClr,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select Bank',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrim,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Search box
                      TextField(
                        style: TextStyle(color: textPrim),
                        decoration: InputDecoration(
                          hintText: 'Search bank (e.g. UCO, SBI...)',
                          hintStyle: TextStyle(color: textSec.withOpacity(0.7)),
                          prefixIcon: Icon(Icons.search, color: textSec),
                          filled: true,
                          fillColor: inputBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderClr),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderClr),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF00E676), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (val) {
                          setBottomSheetState(() {
                            _bankSearchQuery = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // List of banks
                      Expanded(
                        child: filteredBanks.isEmpty
                            ? Center(
                                child: Text(
                                  'No banks match your search',
                                  style: TextStyle(color: textSec),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: filteredBanks.length,
                                itemBuilder: (context, index) {
                                  final bank = filteredBanks[index];
                                  final isSelected = _selectedBankName == bank;
                                  return ListTile(
                                    title: Text(
                                      bank,
                                      style: TextStyle(
                                        color: isSelected
                                            ? const Color(0xFF00E676)
                                            : textPrim,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? const Icon(Icons.check, color: Color(0xFF00E676))
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedBankName = bank;
                                      });
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).then((_) {
      // Clear query when sheet dismissed
      _bankSearchQuery = '';
    });
  }

  Future<void> _pickHawalaTxScreenshot() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null) {
        setState(() {
          if (result.files.single.bytes != null) {
            _hawalaTxScreenshotBytes = result.files.single.bytes;
          } else if (result.files.single.path != null) {
            _hawalaTxScreenshotFile = File(result.files.single.path!);
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction proof screenshot loaded successfully.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking screenshot: $e')),
        );
      }
    }
  }

  String _primaryMethod = 'bank'; // bank, upi, or hawala
  bool _isHawalaSaved = false;
  String _allottedAgentName = '';
  String _selectedAssetType = 'Cash';
  String? _selectedBankName;

  static const List<String> _majorIndianBanks = [
    // Major Commercial Banks
    'State Bank of India',
    'HDFC Bank',
    'ICICI Bank',
    'Axis Bank',
    'Kotak Mahindra Bank',
    'Punjab National Bank',
    'Bank of Baroda',
    'Canara Bank',
    'Union Bank of India',
    'IndusInd Bank',
    'YES Bank',
    'IDFC FIRST Bank',
    'Bank of India',
    'Central Bank of India',
    'Indian Bank',
    'UCO Bank',
    'Indian Overseas Bank',
    'Federal Bank',
    'South Indian Bank',
    'RBL Bank',
    'Bandhan Bank',

    // Small Finance Banks
    'AU Small Finance Bank',
    'Equitas Small Finance Bank',
    'Ujjivan Small Finance Bank',
    'Jana Small Finance Bank',
    'Capital Small Finance Bank',
    'ESAF Small Finance Bank',
    'Fincare Small Finance Bank',
    'Suryoday Small Finance Bank',
    'Utkarsh Small Finance Bank',
    'Shivalik Small Finance Bank',
    'Unity Small Finance Bank',

    // Payments Banks
    'Airtel Payments Bank',
    'Paytm Payments Bank',
    'India Post Payments Bank',
    'Fino Payments Bank',
    'Jio Payments Bank',
    'NSDL Payments Bank',

    // Gramin (Regional Rural) Banks
    'Rajasthan Marudhara Gramin Bank',
    'Baroda Rajasthan Kshetriya Gramin Bank',
    'Uttar Bihar Gramin Bank',
    'Sarva Haryana Gramin Bank',
    'Prathama UP Gramin Bank',
    'Aryavart Bank',
    'Madhyanchal Gramin Bank',
    'Maharashtra Gramin Bank',
    'Vidharbha Konkan Gramin Bank',
    'Saurashtra Gramin Bank',
    'Karnataka Gramin Bank',
    'Karnataka Vikas Grameena Bank',
    'Andhra Pragathi Grameena Bank',
    'Kerala Gramin Bank',
    'Paschim Banga Gramin Bank',
    'Assam Gramin Vikash Bank',
    'Jharkhand State Gramin Bank',
  ];
  String? _selectedState;
  String? _selectedDistrict;


  void _onStateChanged(String? newState) {
    if (newState != null) {
      setState(() {
        _selectedState = newState;
        _stateController.text = newState;
        final districts = IndianGeography.statesAndDistricts[newState] ?? [];
        _selectedDistrict = districts.isNotEmpty ? districts.first : null;
        _districtController.text = _selectedDistrict ?? '';
      });
    }
  }

  Future<void> _launchTelegram() async {
    final hash = _hawalaTxHashController.text.trim();
    final asset = _selectedAssetType;
    final stateStr = _stateController.text;
    final districtStr = _districtController.text;

    final messageText = "Hello! I have deposited my USDT to the 777 USDT Gateway India.\n\n"
        "Transaction Hash (TXID): $hash\n"
        "Allotted Agent ID: $_allottedAgentName\n"
        "Asset Selected: $asset\n"
        "Location: $districtStr, $stateStr\n\n"
        "Please authorize my Hawala payout.";

    try {
      await Clipboard.setData(ClipboardData(text: messageText));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📋 Payout details copied! Just paste in Telegram chat.'),
            backgroundColor: Color(0xFF00E676),
          ),
        );
      }
    } catch (_) {}

    final nativeUrl = Uri.parse('tg://resolve?domain=therockymerchant');
    final webUrl = Uri.parse('https://t.me/therockymerchant');
    try {
      final launched = await launchUrl(nativeUrl, mode: LaunchMode.externalNonBrowserApplication);
      if (!launched) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Telegram. Contact support at support@777.com')),
          );
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    ScreenSecurity.protectScreen();

    final state = ref.read(bankDetailsNotifierProvider);
    _accountNumberController = TextEditingController(text: state.accountNumber);
    _confirmAccountNumberController = TextEditingController(
      text: state.accountNumber,
    );
    _ifscController = TextEditingController(text: state.ifscCode);
    _holderNameController = TextEditingController(
      text: state.accountHolderName,
    );
    _upiIdController = TextEditingController(text: state.upiId);
    _addressController = TextEditingController();
    _districtController = TextEditingController(text: 'Jaipur');
    _stateController = TextEditingController(text: 'Rajasthan');
    _hawalaTxHashController = TextEditingController();
    _selectedState = 'Rajasthan';
    _selectedDistrict = 'Jaipur';
    _selectedBankName = 'State Bank of India';

    if (state.upiId.isNotEmpty && state.accountNumber.isEmpty) {
      _primaryMethod = 'upi';
    }
  }

  @override
  void dispose() {
    ScreenSecurity.unprotectScreen();
    _accountNumberController.dispose();
    _confirmAccountNumberController.dispose();
    _ifscController.dispose();
    _holderNameController.dispose();
    _upiIdController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _hawalaTxHashController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickQrCode() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null) {
        if (result.files.single.bytes != null) {
          ref
              .read(bankDetailsNotifierProvider.notifier)
              .updateField(
                upiQrBytes: result.files.single.bytes,
                upiQrFileName: result.files.single.name,
              );
        } else if (result.files.single.path != null) {
          ref
              .read(bankDetailsNotifierProvider.notifier)
              .updateField(
                upiQrFile: File(result.files.single.path!),
                upiQrFileName: result.files.single.name,
              );
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('UPI QR Code screenshot loaded successfully.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking QR screenshot: $e')),
        );
      }
    }
  }

  void _onSaveTrigger() async {
    if (!_formKey.currentState!.validate()) return;

    final state = ref.read(bankDetailsNotifierProvider);
    if (_primaryMethod == 'upi') {
      if (state.upiQrFile == null &&
          state.upiQrBytes == null &&
          (state.upiQrUrl == null || state.upiQrUrl!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'UPI QR Code Screenshot is mandatory for UPI payout setup.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    if (_primaryMethod == 'hawala') {
      if (_hawalaTxScreenshotFile == null &&
          _hawalaTxScreenshotBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'USDT Transaction Screenshot is mandatory for Hawala activation.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    // Update fields in notifier if not Hawala
    if (_primaryMethod != 'hawala') {
      ref
          .read(bankDetailsNotifierProvider.notifier)
          .updateField(
            accountNumber: _accountNumberController.text,
            confirmAccountNumber: _confirmAccountNumberController.text,
            ifscCode: _ifscController.text,
            accountHolderName: _holderNameController.text,
            upiId: _upiIdController.text,
          );
    }

    // Show password confirmation dialog
    _showPasswordConfirmationDialog();
  }

  void _showPasswordConfirmationDialog() {
    _passwordController.clear();
    _isPasswordVisible = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final state = ref.watch(bankDetailsNotifierProvider);

            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(Icons.lock_outline, color: Color(0xFF00E676), size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Confirm Modifications',
                    style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Form(
                key: _passwordFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Please enter your account password to authorize and apply modifications.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: const TextStyle(color: Color(0xFFF8FAFC)),
                      decoration: InputDecoration(
                        labelText: 'Enter Password',
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        hintText: '••••••',
                        hintStyle: const TextStyle(color: Color(0xFF475569)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: const Color(0xFF94A3B8),
                            size: 20,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 4) {
                          return 'Password must be at least 4 characters';
                        }
                        return null;
                      },
                    ),
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          state.error!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    ref.read(bankDetailsNotifierProvider.notifier).resetVerification();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
                ElevatedButton(
                  onPressed: state.loading
                      ? null
                      : () => _verifyPasswordAndSave(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: const Color(0xFF0B0F19),
                    minimumSize: const Size(100, 44),
                  ),
                  child: state.loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              Color(0xFF0B0F19),
                            ),
                          ),
                        )
                      : const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _verifyPasswordAndSave(BuildContext dialogContext) async {
    if (!_passwordFormKey.currentState!.validate()) return;

    // Simulate OTP verification step so notifier becomes verified
    final verified = await ref
        .read(bankDetailsNotifierProvider.notifier)
        .verifyModificationOtp('123456');

    if (verified) {
      if (_primaryMethod == 'hawala') {
        if (dialogContext.mounted) {
          Navigator.pop(dialogContext); // Close dialog
        }
        setState(() {
          _isHawalaSaved = true;
          _allottedAgentName = 'OTC_AGENT_777';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hawala Cash Pickup setup complete! Agent allotted.'),
            ),
          );
        }
      } else {
        final saved = await ref
            .read(bankDetailsNotifierProvider.notifier)
            .saveBankDetails();
        if (dialogContext.mounted) {
          Navigator.pop(dialogContext); // Always close dialog!
        }
        if (saved) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFF00E676),
                content: Text(
                  'Payout credentials updated successfully.',
                  style: TextStyle(color: Color(0xFF0B0F19), fontWeight: FontWeight.bold),
                ),
              ),
            );
            context.go('/home'); // Go back to Home cleanly
          }
        } else {
          if (mounted) {
            final errorMsg = ref.read(bankDetailsNotifierProvider).error ?? 'Failed to update payout details. Please try again.';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.redAccent,
                content: Text(errorMsg),
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankState = ref.watch(bankDetailsNotifierProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgClr = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8F9FA);
    final cardClr = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderClr = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrim = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final textSec = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final activeGreen = isDark ? const Color(0xFF00E676) : const Color(0xFF0F9D58);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/home');
      },
      child: AppScaffold(
      backgroundColor: bgClr,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Bank & Payout Setup'),
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
              // Security Warning Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock, color: Color(0xFFEF4444), size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '⚠️ Enter details carefully. 777 Gateway is not responsible for wrong transfers.',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Primary Payout Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrim,
                ),
              ),
              const SizedBox(height: 12),

              // Segmented Tab style radio selection
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _primaryMethod = 'bank'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _primaryMethod == 'bank'
                              ? activeGreen.withOpacity(0.15)
                              : cardClr,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _primaryMethod == 'bank'
                                ? activeGreen
                                : borderClr,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_balance,
                              size: 16,
                              color: _primaryMethod == 'bank'
                                  ? activeGreen
                                  : textSec,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Bank',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _primaryMethod == 'bank'
                                    ? activeGreen
                                    : textSec,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _primaryMethod = 'upi'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _primaryMethod == 'upi'
                              ? activeGreen.withOpacity(0.15)
                              : cardClr,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _primaryMethod == 'upi'
                                ? activeGreen
                                : borderClr,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code,
                              size: 16,
                              color: _primaryMethod == 'upi'
                                  ? activeGreen
                                  : textSec,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'UPI / QR',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _primaryMethod == 'upi'
                                    ? activeGreen
                                    : textSec,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _primaryMethod = 'hawala'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _primaryMethod == 'hawala'
                              ? activeGreen.withOpacity(0.15)
                              : cardClr,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _primaryMethod == 'hawala'
                                ? activeGreen
                                : borderClr,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_shipping_outlined,
                              size: 16,
                              color: _primaryMethod == 'hawala'
                                  ? activeGreen
                                  : textSec,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Hawala',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _primaryMethod == 'hawala'
                                    ? activeGreen
                                    : textSec,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_primaryMethod == 'bank') ...[
                // Account Holder Name (Shared)
                TextFormField(
                  controller: _holderNameController,
                  style: TextStyle(color: textPrim),
                  decoration: InputDecoration(
                    labelText: 'Account Holder Name',
                    labelStyle: TextStyle(color: textSec),
                    hintText: 'Enter name matches bank records',
                    hintStyle: TextStyle(color: textSec.withOpacity(0.7)),
                  ),
                  validator: (value) {
                    if (_primaryMethod == 'bank') {
                      if (value == null || value.isEmpty) {
                        return 'Please enter account holder name';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              if (_primaryMethod == 'hawala') ...[
                // Limit card warning
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orangeAccent, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orangeAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Note: Hawala is only applicable for transactions of minimum 2000 USDT.',
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_isHawalaSaved) ...[
                  // Allocated Agent Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: activeGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: activeGreen, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.stars, color: activeGreen, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'HAWALA AGENT ALLOCATED',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: activeGreen,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Agent ID: $_allottedAgentName',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrim),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Asset Selected: $_selectedAssetType',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: activeGreen),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Location: ${_districtController.text}, ${_stateController.text}',
                          style: TextStyle(fontSize: 13, color: textSec),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Transaction Hash: ${_hawalaTxHashController.text}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrim),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Status: Active & Waiting for Payout confirmation. Text the agent on Telegram to coordinate cash delivery.',
                          style: TextStyle(fontSize: 12, color: textSec),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _launchTelegram,
                          icon: const Icon(Icons.send_rounded),
                          label: const Text('Text Agent on Telegram'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: activeGreen,
                            foregroundColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  // Hawala Asset Selection Fields (Custom Bottom Sheet Selector)
                  _buildBottomSheetSelector(
                    label: 'Select Asset Type',
                    value: _selectedAssetType,
                    onTap: () {
                      _showSelectionBottomSheet(
                        title: 'Select Asset Type',
                        items: ['Gold', 'Silver', 'Cash'],
                        selectedValue: _selectedAssetType,
                        onSelected: (val) => setState(() => _selectedAssetType = val),
                      );
                    },
                  ),
                  if (_primaryMethod == 'hawala' && _selectedAssetType == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 12),
                      child: Text('Please select an asset type', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                    ),
                  const SizedBox(height: 16),

                  // State Dropdown
                  _buildBottomSheetSelector(
                    label: 'State',
                    value: _selectedState,
                    onTap: () {
                      _showSelectionBottomSheet(
                        title: 'Select State',
                        items: IndianGeography.statesAndDistricts.keys.toList(),
                        selectedValue: _selectedState,
                        onSelected: (val) {
                          _onStateChanged(val);
                        },
                      );
                    },
                  ),
                  if (_primaryMethod == 'hawala' && _selectedState == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 12),
                      child: Text('Please select a state', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                    ),
                  const SizedBox(height: 16),

                  // District Dropdown
                  _buildBottomSheetSelector(
                    label: 'District',
                    value: _selectedDistrict,
                    onTap: () {
                      if (_selectedState == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a state first')));
                        return;
                      }
                      _showSelectionBottomSheet(
                        title: 'Select District',
                        items: IndianGeography.statesAndDistricts[_selectedState] ?? [],
                        selectedValue: _selectedDistrict,
                        onSelected: (val) {
                          setState(() {
                            _selectedDistrict = val;
                            _districtController.text = val;
                          });
                        },
                      );
                    },
                  ),
                  if (_primaryMethod == 'hawala' && _selectedDistrict == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 12),
                      child: Text('Please select a district', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                    ),
                  const SizedBox(height: 24),

                  // Transaction Proof Section
                  const Divider(height: 32, color: Colors.blueGrey),
                  const SizedBox(height: 8),
                  Text(
                    'USDT Transaction Proof (Verification Required)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textPrim,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Upload a screenshot of your USDT transfer and enter the transaction hash / TXID to activate your Hawala payout.',
                    style: TextStyle(fontSize: 12, color: textSec),
                  ),
                  const SizedBox(height: 16),

                  // Screenshot upload button
                  OutlinedButton(
                    onPressed: _pickHawalaTxScreenshot,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor:
                          (_hawalaTxScreenshotFile != null ||
                              _hawalaTxScreenshotBytes != null)
                          ? activeGreen.withOpacity(0.1)
                          : cardClr,
                      side: BorderSide(
                        color:
                            (_hawalaTxScreenshotFile != null ||
                                _hawalaTxScreenshotBytes != null)
                            ? activeGreen
                            : borderClr,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          (_hawalaTxScreenshotFile != null ||
                                  _hawalaTxScreenshotBytes != null)
                              ? Icons.check_circle
                              : Icons.photo_library_outlined,
                          color:
                              (_hawalaTxScreenshotFile != null ||
                                  _hawalaTxScreenshotBytes != null)
                              ? activeGreen
                              : textSec,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upload USDT Transfer Screenshot *',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      (_hawalaTxScreenshotFile != null ||
                                          _hawalaTxScreenshotBytes != null)
                                      ? activeGreen
                                      : textPrim,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                (_hawalaTxScreenshotFile != null ||
                                        _hawalaTxScreenshotBytes != null)
                                    ? 'Screenshot loaded ✓'
                                    : 'Required screenshot showing successful USDT payment (Mandatory)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      (_hawalaTxScreenshotFile != null ||
                                          _hawalaTxScreenshotBytes != null)
                                      ? activeGreen.withOpacity(0.8)
                                      : textSec,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Transaction hash / TXID field
                  TextFormField(
                    controller: _hawalaTxHashController,
                    style: TextStyle(color: textPrim),
                    decoration: InputDecoration(
                      labelText: 'USDT Transaction Hash / TXID *',
                      labelStyle: TextStyle(color: textSec),
                      hintText: 'Enter TXID (e.g. 0x742d35Cc6634C...)',
                      hintStyle: TextStyle(color: textSec.withOpacity(0.7)),
                    ),
                    validator: (value) {
                      if (_primaryMethod == 'hawala') {
                        if (value == null || value.isEmpty) {
                          return 'Please enter transaction hash/TXID';
                        }
                        if (value.trim().length < 16) {
                          return 'Enter a valid transaction hash';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ],

              if (_primaryMethod == 'bank') ...[
                // Bank Name Search Selector
                GestureDetector(
                  onTap: _showSearchableBankBottomSheet,
                  child: AbsorbPointer(
                    child: TextFormField(
                      key: ValueKey('bank_field_$_selectedBankName'),
                      style: TextStyle(color: textPrim),
                      decoration: InputDecoration(
                        labelText: 'Select Bank',
                        labelStyle: TextStyle(color: textSec),
                        hintText: 'Tap to search & select your bank',
                        hintStyle: TextStyle(color: textSec.withOpacity(0.7)),
                        suffixIcon: Icon(Icons.arrow_drop_down, color: textSec),
                      ),
                      controller: TextEditingController(text: _selectedBankName),
                      validator: (value) {
                        if (_primaryMethod == 'bank' && (_selectedBankName == null || _selectedBankName!.isEmpty)) {
                          return 'Please select your bank';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Bank Details
                TextFormField(
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textPrim),
                  decoration: InputDecoration(
                    labelText: 'Bank Account Number',
                    labelStyle: TextStyle(color: textSec),
                    hintText: 'Enter bank account number',
                    hintStyle: TextStyle(color: textSec.withOpacity(0.7)),
                  ),
                  validator: (value) {
                    if (_primaryMethod == 'bank') {
                      if (value == null || value.isEmpty) {
                        return 'Enter bank account number';
                      }
                      if (value.length < 9 || value.length > 18) {
                        return 'Enter a valid bank account number';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmAccountNumberController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textPrim),
                  decoration: InputDecoration(
                    labelText: 'Confirm Bank Account Number',
                    labelStyle: TextStyle(color: textSec),
                    hintText: 'Re-enter bank account number',
                    hintStyle: TextStyle(color: textSec.withOpacity(0.7)),
                  ),
                  validator: (value) {
                    if (_primaryMethod == 'bank') {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm account number';
                      }
                      if (value != _accountNumberController.text) {
                        return 'Account numbers do not match';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // IFSC Code
                TextFormField(
                  controller: _ifscController,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    TextInputFormatter.withFunction(
                      (oldValue, newValue) => newValue.copyWith(
                        text: newValue.text.toUpperCase(),
                      ),
                    ),
                  ],
                  style: TextStyle(color: textPrim),
                  decoration: InputDecoration(
                    labelText: 'IFSC Code',
                    labelStyle: TextStyle(color: textSec),
                    hintText: 'e.g. HDFC0000123',
                    hintStyle: TextStyle(color: textSec.withOpacity(0.7)),
                  ),
                  onChanged: (value) {
                    if (value.trim().length == 11) {
                      ref
                          .read(bankDetailsNotifierProvider.notifier)
                          .lookupIfsc(value.trim());
                    }
                  },
                  validator: (value) {
                    if (_primaryMethod == 'bank') {
                      if (value == null || value.isEmpty) {
                        return 'Enter IFSC code';
                      }
                      if (!RegExp(
                        r'^[A-Z]{4}0[A-Z0-9]{6}$',
                      ).hasMatch(value.trim().toUpperCase())) {
                        return 'Enter valid 11-digit IFSC (e.g. SBIN0001234)';
                      }
                    }
                    return null;
                  },
                ),
                if (bankState.bankName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      'Detected Bank: ${bankState.bankName}',
                      style: TextStyle(
                        color: activeGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ] else if (_primaryMethod == 'upi') ...[
                // UPI Details
                TextFormField(
                  controller: _upiIdController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: textPrim),
                  decoration: InputDecoration(
                    labelText: 'UPI ID (VPA)',
                    labelStyle: TextStyle(color: textSec),
                    hintText: 'e.g. username@bank',
                    hintStyle: TextStyle(color: textSec.withOpacity(0.7)),
                  ),
                  validator: (value) {
                    if (_primaryMethod == 'upi') {
                      if (value == null || value.isEmpty) {
                        return 'Enter UPI ID';
                      }
                      if (!RegExp(
                        r'^[\w\.\-_]{2,256}@[\w\.\-_]{2,256}$',
                      ).hasMatch(value.trim())) {
                        return 'Enter a valid UPI ID format (e.g. payee@okaxis)';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Mandatory UPI QR Code Photo Upload Card
                OutlinedButton(
                  onPressed: _pickQrCode,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor:
                        (bankState.upiQrFile != null ||
                            bankState.upiQrBytes != null ||
                            bankState.upiQrUrl != null)
                        ? activeGreen.withOpacity(0.1)
                        : cardClr,
                    side: BorderSide(
                      color:
                          (bankState.upiQrFile != null ||
                              bankState.upiQrBytes != null ||
                              bankState.upiQrUrl != null)
                          ? activeGreen
                          : borderClr,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        (bankState.upiQrFile != null ||
                                bankState.upiQrBytes != null ||
                                bankState.upiQrUrl != null)
                            ? Icons.check_circle
                            : Icons.qr_code_scanner,
                        color:
                            (bankState.upiQrFile != null ||
                                bankState.upiQrBytes != null ||
                                bankState.upiQrUrl != null)
                            ? activeGreen
                            : textSec,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload UPI QR Code (Screenshot only) *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color:
                                    (bankState.upiQrFile != null ||
                                        bankState.upiQrBytes != null ||
                                        bankState.upiQrUrl != null)
                                    ? activeGreen
                                    : textPrim,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (bankState.upiQrFile != null ||
                                      bankState.upiQrBytes != null ||
                                      bankState.upiQrUrl != null)
                                  ? 'QR Code Screenshot loaded ✓'
                                  : 'Required screenshot of your UPI QR code (Mandatory)',
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    (bankState.upiQrFile != null ||
                                        bankState.upiQrBytes != null ||
                                        bankState.upiQrUrl != null)
                                    ? activeGreen.withOpacity(0.8)
                                    : textSec,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              if (bankState.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    bankState.error!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ),

              if (!(_primaryMethod == 'hawala' && _isHawalaSaved))
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
                    onPressed: bankState.loading ? null : _onSaveTrigger,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeGreen,
                      foregroundColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: bankState.loading
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
                        : const Text('Save Payout Details'),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

  void _showSelectionBottomSheet({
    required String title,
    required List<String> items,
    required String? selectedValue,
    required Function(String) onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgClr = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrim = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);

    showModalBottomSheet(
      context: context,
      backgroundColor: bgClr,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: textPrim,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = item == selectedValue;
                      return ListTile(
                        title: Text(
                          item,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF00E676) : textPrim,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Color(0xFF00E676))
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          onSelected(item);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBottomSheetSelector({
    required String label,
    required String? value,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrim = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final textSec = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderClr = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderClr),
          color: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF1F5F9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: textSec, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value ?? 'Select',
                  style: TextStyle(
                    color: value != null ? textPrim : textSec,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Icon(Icons.arrow_drop_down_circle, color: textSec, size: 20),
          ],
        ),
      ),
    );
  }
}