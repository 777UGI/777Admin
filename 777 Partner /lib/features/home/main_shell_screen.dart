import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../core/theme/theme.dart";
import "../dashboard/dashboard_screen.dart";
import "../dashboard/partner_providers.dart";
import "../merchants/merchants_screen.dart";
import "../onboard/onboard_seller_screen.dart";
import "../transactions/transactions_screen.dart";
import "../profile/profile_screen.dart";

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _currentIndex = 0;

  void _onItemTapped(int index, bool isBankComplete) {
    if (index == 2 && !isBankComplete) {
      _showBankRequiredDialog();
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _showBankRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_rounded, color: AppTheme.warning, size: 24),
            SizedBox(width: 10),
            Text(
              "Setup Bank Account First",
              style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          "Admin onboards partners without bank details. Please configure your payout Bank Account or UPI ID in Profile to unlock merchant onboarding and receive commission payouts.",
          style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Later"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _currentIndex = 4); // Go to Profile
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Configure Bank Now"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(partnerDashboardProvider);
    final data = dashboardAsync.asData?.value;
    final bank = data?["partner"]?["bankDetails"] as Map<String, dynamic>? ?? {};
    final hasAccount = (bank["accountNumber"]?.toString().trim().isNotEmpty ?? false);
    final hasUpi = (bank["upiId"]?.toString().trim().isNotEmpty ?? false);
    final isBankComplete = hasAccount || hasUpi;

    final List<Widget> screens = [
      DashboardScreen(
        onNavigateToOnboard: () => _onItemTapped(2, isBankComplete),
        onNavigateToProfile: () => setState(() => _currentIndex = 4),
        onNavigateToMerchants: () => setState(() => _currentIndex = 1),
      ),
      const MerchantsScreen(),
      OnboardSellerScreen(
        onNavigateToProfile: () => setState(() => _currentIndex = 4),
      ),
      const TransactionsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.darkBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: AppTheme.darkSurfaceColor.withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: AppTheme.darkBorderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, "Dashboard", isBankComplete),
                _buildNavItem(1, Icons.storefront_rounded, "Merchants", isBankComplete),

                // ==============================================================
                // ⭐ HIGHLIGHTED ONBOARD CENTER BUTTON (Seller App Style) ⭐
                // ==============================================================
                GestureDetector(
                  onTap: () => _onItemTapped(2, isBankComplete),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9933), Color(0xFF138808)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF138808).withValues(alpha: 0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isBankComplete ? Icons.person_add_alt_1_rounded : Icons.lock_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "ONBOARD",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                _buildNavItem(3, Icons.receipt_long_rounded, "Ledger", isBankComplete),
                _buildNavItem(4, Icons.person_rounded, "Profile", isBankComplete),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isBankComplete) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index, isBankComplete),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.darkTextSecondary,
              size: isSelected ? 24 : 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.darkTextSecondary,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
