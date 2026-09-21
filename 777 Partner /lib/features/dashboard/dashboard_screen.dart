import "dart:async";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../core/theme/theme.dart";
import "partner_providers.dart";

class DashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToOnboard;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onNavigateToMerchants;

  const DashboardScreen({
    super.key,
    this.onNavigateToOnboard,
    this.onNavigateToProfile,
    this.onNavigateToMerchants,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _calcController = TextEditingController(text: "1000");
  double _calcUsdt = 1000.0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Auto sync rates and partner earnings every 10 seconds in background
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        ref.invalidate(partnerDashboardProvider);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _calcController.dispose();
    super.dispose();
  }



  void _addCalcPreset(double amount) {
    setState(() {
      _calcUsdt = amount;
      _calcController.text = amount.toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(partnerDashboardProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBackgroundColor,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                "assets/partner_logo.jpeg",
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppTheme.primaryColor,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "777 Partner",
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppTheme.darkTextPrimary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryColor),
            tooltip: "Refresh",
            onPressed: () => ref.invalidate(partnerDashboardProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.error),
                const SizedBox(height: 12),
                Text("Connection error: $err", style: const TextStyle(color: AppTheme.darkTextSecondary), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(partnerDashboardProvider),
                  child: const Text("Retry Connection"),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final partner = (data["partner"] as Map<String, dynamic>?) ?? {};
          final stats = (data["stats"] as Map<String, dynamic>?) ?? {};
          final rates = (data["rates"] as Map<String, dynamic>?) ?? {};

          final partnerName = partner["name"]?.toString() ?? "Partner Agent";
          final referralCode = partner["referralCode"]?.toString() ?? "AGENT001";
          
          final double exchangeRate = (rates["exchangeRate"] as num?)?.toDouble() ?? 92.5;
          final double commPercent = (partner["commissionPercent"] as num?)?.toDouble()
              ?? (rates["commissionPercent"] as num?)?.toDouble()
              ?? (rates["partnerRate"] as num?)?.toDouble()
              ?? 0.50;
          final double sellingRate = (rates["sellingRate"] as num?)?.toDouble() ?? 93.5;

          final double clientPays = _calcUsdt * exchangeRate;
          final double partnerCommUsdt = _calcUsdt * (commPercent / 100.0);
          final double partnerCommInr = partnerCommUsdt * sellingRate;

          final totalMerchants = stats["totalMerchants"] ?? 0;
          final earnedUsdt = (stats["totalCommissionEarnedUsdt"] as num?)?.toDouble() ?? 0.00;

          // Dynamic Available Commission derived directly from volume * commissionPercent:
          // Scales immediately whenever admin updates commissionPercent (e.g. 0.5% -> 1.0% -> 100%) or exchangeRate
          final double availableUsdt = (stats["availableBalanceUsdt"] as num?)?.toDouble() ?? (earnedUsdt * (commPercent / 100.0));
          final double availableInr = (stats["availableBalanceInr"] as num?)?.toDouble() ?? (availableUsdt * sellingRate);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(partnerDashboardProvider),
            color: AppTheme.primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hello, $partnerName 👋",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkTextPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "VIP Agent Tier • $referralCode • ${commPercent.toStringAsFixed(2)}% Comm",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryLight),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(radius: 3, backgroundColor: AppTheme.primaryColor),
                            SizedBox(width: 5),
                            Text("ACTIVE", style: TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ==========================================
                  // 1. EXACT SELLER APP EMERALD HERO CARD
                  // ==========================================
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.heroCardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Available Commission Payout",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                referralCode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Balance in Big Bold Font
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "₹${availableInr.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "≈ ${availableUsdt.toStringAsFixed(2)} USDT",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Automated Payout Schedule Notice
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.event_available_rounded, size: 14, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Automatic Payout: Every Sunday 10:00 PM IST",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==========================================
                  // 2. WEEKLY PERFORMANCE STATS
                  // ==========================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Weekly Performance",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.darkTextPrimary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 7, color: AppTheme.primaryColor),
                            SizedBox(width: 5),
                            Text(
                              "LIVE SYNC",
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Volume this week (USDT prominent on top, INR below)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: AppTheme.cardDecoration(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Volume this week",
                              style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "${earnedUsdt.toStringAsFixed(2)} USDT",
                              style: const TextStyle(
                                color: AppTheme.primaryLight,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "≈ ₹${(earnedUsdt * exchangeRate).toStringAsFixed(0)} INR",
                              style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF26A17B).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF26A17B).withValues(alpha: 0.35), width: 1.5),
                          ),
                          padding: const EdgeInsets.all(7),
                          child: Image.asset(
                            "assets/usdt_logo.png",
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Two columns below: Total Merchants & Weekly Earning
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          title: "Total Merchants",
                          value: totalMerchants.toString(),
                          subtitle: "Active Sellers →",
                          icon: Icons.storefront_rounded,
                          iconColor: AppTheme.primaryColor,
                          onTap: () => widget.onNavigateToMerchants?.call(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          title: "Weekly Earning",
                          value: "₹${availableInr.toStringAsFixed(0)}",
                          subtitle: "≈ ${availableUsdt.toStringAsFixed(1)} USDT",
                          icon: Icons.calendar_today_rounded,
                          iconColor: AppTheme.accentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ==========================================
                  // 4. LIVE OTC RATES TICKER (Seller Card Style)
                  // ==========================================
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: AppTheme.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.currency_exchange_rounded, size: 18, color: AppTheme.primaryColor),
                                SizedBox(width: 8),
                                Text(
                                  "Live System Rates",
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.darkTextPrimary),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "REALTIME",
                                style: TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRateSubItem("Live Buying Rate", "₹${exchangeRate.toStringAsFixed(2)}"),
                            ),
                            Container(width: 1, height: 32, color: AppTheme.darkBorderColor),
                            Expanded(
                              child: _buildRateSubItem("Partner Cut", "${commPercent.toStringAsFixed(2)}%", highlight: true),
                            ),
                            Container(width: 1, height: 32, color: AppTheme.darkBorderColor),
                            Expanded(
                              child: _buildRateSubItem("Selling Rate", "₹${sellingRate.toStringAsFixed(2)}"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ==========================================
                  // 5. QUICK USDT CALCULATOR CHIPS
                  // ==========================================
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: AppTheme.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Commission Estimator (${commPercent.toStringAsFixed(2)}%)",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.darkTextPrimary),
                            ),
                            Icon(Icons.calculate_outlined, color: AppTheme.primaryColor, size: 20),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Fast Preset Chips
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildPresetChip(100),
                            _buildPresetChip(500),
                            _buildPresetChip(1000),
                            _buildPresetChip(5000),
                          ],
                        ),
                        const SizedBox(height: 14),

                        TextField(
                          controller: _calcController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            labelText: "USDT Trading Volume",
                            suffixText: "USDT",
                          ),
                          onChanged: (val) {
                            setState(() {
                              _calcUsdt = double.tryParse(val) ?? 0.0;
                            });
                          },
                        ),
                        const SizedBox(height: 14),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.darkSurfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.darkBorderColor),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Merchant Pays", style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 11)),
                                  Text(
                                    "₹${clientPays.toStringAsFixed(0)}",
                                    style: const TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("Your Net Commission (${commPercent.toStringAsFixed(2)}%)", style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.w600)),
                                  Text(
                                    "+ ₹${partnerCommInr.toStringAsFixed(2)}",
                                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w900, fontSize: 16),
                                  ),
                                  Text(
                                    "≈ ${partnerCommUsdt.toStringAsFixed(2)} USDT",
                                    style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    final tile = Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Icon(icon, color: iconColor, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(color: AppTheme.darkTextPrimary, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: tile,
      );
    }
    return tile;
  }

  Widget _buildRateSubItem(String label, String value, {bool highlight = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: highlight ? AppTheme.primaryColor : AppTheme.darkTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(double amount) {
    final isSelected = _calcUsdt == amount;
    return ChoiceChip(
      label: Text("+${amount.toStringAsFixed(0)}"),
      selected: isSelected,
      onSelected: (_) => _addCalcPreset(amount),
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      backgroundColor: AppTheme.darkSurfaceElevated,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.darkTextSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : AppTheme.darkBorderColor,
      ),
    );
  }
}
