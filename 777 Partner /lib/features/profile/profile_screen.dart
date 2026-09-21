import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../../core/theme/theme.dart";
import "../../core/utils/telegram_help_desk.dart";
import "../auth/auth_controller.dart";
import "../dashboard/partner_providers.dart";

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _holderNameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _confirmAccountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _upiController = TextEditingController();

  bool _isSavingBank = false;

  static const List<String> _majorIndianBanks = [
    // Major Public Sector / Government Banks
    "State Bank of India",
    "Punjab National Bank",
    "Bank of Baroda",
    "Canara Bank",
    "Union Bank of India",
    "Bank of India",
    "Central Bank of India",
    "Indian Bank",
    "UCO Bank",
    "Indian Overseas Bank",
    "Punjab & Sind Bank",

    // Major Private Commercial Banks
    "HDFC Bank",
    "ICICI Bank",
    "Axis Bank",
    "Kotak Mahindra Bank",
    "IndusInd Bank",
    "YES Bank",
    "IDFC FIRST Bank",
    "Federal Bank",
    "South Indian Bank",
    "RBL Bank",
    "Bandhan Bank",
    "IDBI Bank",
    "Jammu & Kashmir Bank",
    "Karur Vysya Bank",
    "City Union Bank",
    "Karnataka Bank",
    "Tamilnad Mercantile Bank",

    // Small Finance & Payment Banks
    "AU Small Finance Bank",
    "Equitas Small Finance Bank",
    "Ujjivan Small Finance Bank",
    "Jana Small Finance Bank",
    "Capital Small Finance Bank",
    "ESAF Small Finance Bank",
    "Fincare Small Finance Bank",
    "Suryoday Small Finance Bank",
    "Utkarsh Small Finance Bank",
    "Paytm Payments Bank",
    "Airtel Payments Bank",
    "India Post Payments Bank",
    "Other Bank",
  ];

  @override
  void dispose() {
    _holderNameController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _confirmAccountNumberController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _populateExistingBankDetails(Map<String, dynamic> bank) {
    if (bank.isNotEmpty) {
      if (_bankNameController.text.isEmpty) {
        _bankNameController.text = bank["bankName"]?.toString() ?? "";
      }
      if (_holderNameController.text.isEmpty) {
        _holderNameController.text = bank["accountHolderName"]?.toString() ?? "";
      }
      if (_accountNumberController.text.isEmpty) {
        final acc = bank["accountNumber"]?.toString() ?? "";
        _accountNumberController.text = acc;
        _confirmAccountNumberController.text = acc;
      }
      if (_ifscController.text.isEmpty) {
        _ifscController.text = bank["ifscCode"]?.toString() ?? "";
      }
      if (_upiController.text.isEmpty) {
        _upiController.text = bank["upiId"]?.toString() ?? "";
      }
    }
  }

  void _openBankSelectorDialog(BuildContext sheetContext, Function(String) onBankSelected) {
    showDialog(
      context: sheetContext,
      builder: (dContext) {
        String searchQuery = "";
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredBanks = _majorIndianBanks.where((b) {
              return b.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return Dialog(
              backgroundColor: AppTheme.cardSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Select Bank",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                          onPressed: () => Navigator.pop(dContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      autofocus: false,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: "Search bank (SBI, HDFC, PNB)...",
                        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                        filled: true,
                        fillColor: AppTheme.cardElevated,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) {
                        setDialogState(() => searchQuery = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.40,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: filteredBanks.length,
                          separatorBuilder: (_, _) => const Divider(color: AppTheme.borderSubtle, height: 1),
                          itemBuilder: (ctx, i) {
                            final bName = filteredBanks[i];
                            final isSelected = _bankNameController.text == bName;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              title: Text(
                                bName,
                                style: TextStyle(
                                  color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 20)
                                  : null,
                              onTap: () {
                                onBankSelected(bName);
                                Navigator.pop(dContext);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showBankEditSheet() {
    _confirmAccountNumberController.text = _accountNumberController.text;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isOtherBank = _bankNameController.text == "Other Bank";

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.92,
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.textMuted.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "Payout Bank Account Details",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Commissions are settled automatically every Sunday via IMPS / NEFT.",
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 20),

                        // 1. Account Holder Legal Name
                        TextField(
                          controller: _holderNameController,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            labelText: "Account Holder Legal Name *",
                            hintText: "As per bank passbook / cheque",
                            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.textMuted),
                            filled: true,
                            fillColor: AppTheme.cardElevated,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 2. Bank Name Selector
                        InkWell(
                          onTap: () {
                            _openBankSelectorDialog(ctx, (selected) {
                              setSheetState(() {
                                _bankNameController.text = selected;
                              });
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                            decoration: BoxDecoration(
                              color: AppTheme.cardElevated,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _bankNameController.text.isEmpty
                                    ? AppTheme.dangerRed.withValues(alpha: 0.5)
                                    : AppTheme.borderSubtle,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.account_balance_rounded, color: AppTheme.textMuted),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Bank Name *", style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                      const SizedBox(height: 2),
                                      Text(
                                        _bankNameController.text.isNotEmpty ? _bankNameController.text : "Tap to choose bank...",
                                        style: TextStyle(
                                          color: _bankNameController.text.isNotEmpty ? AppTheme.textPrimary : AppTheme.textMuted,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textMuted),
                              ],
                            ),
                          ),
                        ),

                        if (isOtherBank) ...[
                          const SizedBox(height: 10),
                          TextField(
                            onChanged: (v) => _bankNameController.text = v,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: InputDecoration(
                              labelText: "Type Custom Bank Name",
                              hintText: "Enter full legal bank name",
                              filled: true,
                              fillColor: AppTheme.cardElevated,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),

                        // 3. Bank Account Number
                        TextField(
                          controller: _accountNumberController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          decoration: InputDecoration(
                            labelText: "Bank Account Number *",
                            hintText: "e.g. 100029384756",
                            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            prefixIcon: const Icon(Icons.numbers_rounded, color: AppTheme.textMuted),
                            filled: true,
                            fillColor: AppTheme.cardElevated,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 4. Confirm Bank Account Number
                        TextField(
                          controller: _confirmAccountNumberController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          decoration: InputDecoration(
                            labelText: "Confirm Bank Account Number *",
                            hintText: "Re-enter bank account number",
                            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            prefixIcon: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.textMuted),
                            filled: true,
                            fillColor: AppTheme.cardElevated,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 5. IFSC Code
                        TextField(
                          controller: _ifscController,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(11),
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                          ],
                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                          decoration: InputDecoration(
                            labelText: "IFSC Code *",
                            hintText: "e.g. SBIN0001234",
                            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            prefixIcon: const Icon(Icons.lock_clock_outlined, color: AppTheme.textMuted),
                            filled: true,
                            fillColor: AppTheme.cardElevated,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 6. UPI ID (Optional)
                        TextField(
                          controller: _upiController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: InputDecoration(
                            labelText: "UPI ID (Optional)",
                            hintText: "e.g. username@okhdfcbank",
                            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppTheme.textMuted),
                            filled: true,
                            fillColor: AppTheme.cardElevated,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Save Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _isSavingBank
                              ? null
                              : () async {
                                  final holder = _holderNameController.text.trim();
                                  final bName = _bankNameController.text.trim();
                                  final acc = _accountNumberController.text.trim();
                                  final confAcc = _confirmAccountNumberController.text.trim();
                                  final ifsc = _ifscController.text.trim().toUpperCase();

                                  if (holder.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Please enter Account Holder Legal Name"), backgroundColor: AppTheme.dangerRed),
                                    );
                                    return;
                                  }
                                  if (bName.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Please select Bank Name"), backgroundColor: AppTheme.dangerRed),
                                    );
                                    return;
                                  }
                                  if (acc.isEmpty || acc.length < 8) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Please enter a valid Account Number"), backgroundColor: AppTheme.dangerRed),
                                    );
                                    return;
                                  }
                                  if (acc != confAcc) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Bank Account Numbers do not match!"), backgroundColor: AppTheme.dangerRed),
                                    );
                                    return;
                                  }
                                  if (ifsc.isEmpty || ifsc.length != 11) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Please enter a valid 11-character IFSC Code"), backgroundColor: AppTheme.dangerRed),
                                    );
                                    return;
                                  }

                                  setSheetState(() => _isSavingBank = true);
                                  final service = ref.read(partnerActionServiceProvider);
                                  final success = await service.saveBankDetails(
                                    bankName: bName,
                                    accountHolderName: holder,
                                    accountNumber: acc,
                                    ifscCode: ifsc,
                                    upiId: _upiController.text.trim(),
                                  );
                                  setSheetState(() => _isSavingBank = false);

                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);

                                  ref.invalidate(partnerBankDetailsProvider);
                                  ref.invalidate(partnerDashboardProvider);

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(success ? "Payout Bank Details Saved Successfully!" : "Failed to save bank details"),
                                        backgroundColor: success ? AppTheme.mintGreen : AppTheme.dangerRed,
                                      ),
                                    );
                                  }
                                },
                          child: _isSavingBank
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text("Save & Verify Payout Account", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
          },
        );
      },
    );
  }

  Widget _buildPolicyItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final bankAsync = ref.watch(partnerBankDetailsProvider);
    final withdrawalsAsync = ref.watch(partnerWithdrawalsProvider);

    final dashboardAsync = ref.watch(partnerDashboardProvider);
    final String partnerName = auth.name ?? "Partner Agent";
    String referralCode = auth.referralCode ?? "AGENT001";
    dashboardAsync.whenData((data) {
      final partner = (data["partner"] as Map<String, dynamic>?) ?? {};
      if (partner["referralCode"] != null && partner["referralCode"].toString().isNotEmpty) {
        referralCode = partner["referralCode"].toString();
      }
    });
    final String partnerEmail = auth.email ?? "";

    final bool hasBank = _accountNumberController.text.trim().isNotEmpty &&
        _bankNameController.text.trim().isNotEmpty &&
        _holderNameController.text.trim().isNotEmpty;

    final String bankName = _bankNameController.text.trim();
    final String accNum = _accountNumberController.text.trim();
    final String maskedAcc = accNum.length > 4 ? "•••• •••• ${accNum.substring(accNum.length - 4)}" : accNum;

    return Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      appBar: AppBar(
        title: const Text("Partner Profile & Policy"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.dangerRed),
            tooltip: "Logout",
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go("/login");
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Executive Identity Tile
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecoration(),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                    child: const Icon(Icons.person_rounded, color: AppTheme.primaryColor, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partnerName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(partnerEmail, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.goldAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "CODE: $referralCode",
                                style: const TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ========================================================
            // PAYOUT BANK ACCOUNT CARD (RED ALERT WHEN INCOMPLETE)
            // ========================================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: hasBank
                  ? AppTheme.cardDecoration(borderRadius: 24)
                  : BoxDecoration(
                      color: const Color(0xFF2A1515),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.dangerRed, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.dangerRed.withValues(alpha: 0.15),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            hasBank ? Icons.account_balance_rounded : Icons.warning_amber_rounded,
                            color: hasBank ? AppTheme.appleBlue : AppTheme.dangerRed,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Payout Bank Account",
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                      if (hasBank)
                        TextButton(
                          onPressed: _showBankEditSheet,
                          child: const Text("Edit", style: TextStyle(color: AppTheme.appleBlue, fontWeight: FontWeight.bold)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerRed.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "ACTION REQUIRED",
                            style: TextStyle(color: AppTheme.dangerRed, fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (hasBank) ...[
                    // Completed Bank State
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  bankName,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary),
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.verified, size: 16, color: AppTheme.mintGreen),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Verified",
                                    style: TextStyle(color: AppTheme.mintGreen, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            maskedAcc,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _holderNameController.text.isNotEmpty ? _holderNameController.text : partnerName,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Incomplete Red Warning State
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerRed.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.error_outline_rounded, color: AppTheme.dangerRed, size: 18),
                              SizedBox(width: 8),
                              Text(
                                "Bank Account Not Linked!",
                                style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Admin onboards partners without bank credentials. You must add your bank details to receive weekly Sunday settlements and unlock merchant onboarding.",
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.dangerRed,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _showBankEditSheet,
                              icon: const Icon(Icons.add_card_rounded, size: 16),
                              label: const Text("Link Payout Bank Account Now", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ========================================================
            // TERMS & CONDITIONS (PARTNER OPERATING POLICIES)
            // ========================================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecoration(borderRadius: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.goldAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.policy_rounded, color: AppTheme.goldAccent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Terms & Conditions",
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Partner policies & settlement guidelines",
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Policy 1: Weekly Sunday Payout
                  _buildPolicyItem(
                    icon: Icons.event_available_rounded,
                    iconColor: AppTheme.mintGreen,
                    title: "Weekly Sunday Payouts (10:00 PM IST)",
                    description:
                        "Commissions are automatically credited to your bank account every Sunday by 10:00 PM IST.",
                  ),
                  const Divider(color: AppTheme.borderSubtle, height: 20),

                  // Policy 2: Inactivity & Deboarding Policy
                  _buildPolicyItem(
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppTheme.dangerRed,
                    title: "Inactivity & Deboarding",
                    description:
                        "Accounts inactive for over 1 month will be deboarded. Re-onboarding requires a ₹2,699 security fee.",
                  ),
                  const Divider(color: AppTheme.borderSubtle, height: 20),

                  // Policy 3: Performance Commission Hikes
                  _buildPolicyItem(
                    icon: Icons.trending_up_rounded,
                    iconColor: AppTheme.primaryColor,
                    title: "Performance Commission Hikes",
                    description:
                        "Top-performing partners with consistent volume are eligible for commission rate upgrades by Admin.",
                  ),
                  const Divider(color: AppTheme.borderSubtle, height: 20),

                  // Policy 4: 5% Bank Outing Charges
                  _buildPolicyItem(
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: AppTheme.goldAccent,
                    title: "5% Bank Outing Charges",
                    description:
                        "A 5% outing fee applies when our representative physically visits the bank to deposit cash.",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ========================================================
            // SETTLEMENT HISTORY LIST (AUTOMATED WEEKLY LOG)
            // ========================================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecoration(borderRadius: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Payout History", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
                          SizedBox(height: 2),
                          Text("Automated Weekly Settlements", style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.mintGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "EVERY SUNDAY 10 PM",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.mintGreen),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  withdrawalsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.mintGreen)),
                    error: (e, _) => Text("Failed: $e", style: const TextStyle(color: AppTheme.textMuted)),
                    data: (withdrawals) {
                      if (withdrawals.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Center(child: Text("No payouts recorded yet", style: TextStyle(color: AppTheme.textMuted, fontSize: 13))),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: withdrawals.length,
                        separatorBuilder: (ctx, i) => const Divider(color: AppTheme.borderSubtle, height: 16),
                        itemBuilder: (ctx, i) {
                          final wd = withdrawals[i];
                          final status = wd["status"]?.toString() ?? "pending";
                          final isPaid = status.toLowerCase() == "paid";
                          final refNo = wd["reference"]?.toString() ?? "WD-SETTLE";
                          final num amtInr = (wd["amountInr"] as num?) ?? 0;
                          final String date = wd["createdAt"] != null ? wd["createdAt"].toString().split("T").first : "";

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(refNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                                  Text(date, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("₹${amtInr.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (isPaid ? AppTheme.mintGreen : AppTheme.warningOrange).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: isPaid ? AppTheme.mintGreen : AppTheme.warningOrange,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 24/7 Agent Help Desk
            InkWell(
              onTap: () {
                final tgDesk = ref.read(partnerDashboardProvider).value?["support"]?["telegramAgent"]?.toString() ?? "therockymerchant";
                TelegramHelpDesk.launchDesk(
                  partnerName: partnerName,
                  referralCode: referralCode,
                  partnerEmail: partnerEmail,
                  telegramUsername: tgDesk,
                  context: context,
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: AppTheme.cardDecoration(),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.info.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.support_agent_rounded, color: AppTheme.info, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("24/7 Agent Help Desk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkTextPrimary)),
                          SizedBox(height: 2),
                          Text("Direct Telegram hotline with pre-filled agent details", style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, size: 18, color: AppTheme.info),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}
