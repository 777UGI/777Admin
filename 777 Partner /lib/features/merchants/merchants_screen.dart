import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../core/theme/theme.dart";
import "../dashboard/partner_providers.dart";

class MerchantsScreen extends ConsumerStatefulWidget {
  const MerchantsScreen({super.key});

  @override
  ConsumerState<MerchantsScreen> createState() => _MerchantsScreenState();
}

class _MerchantsScreenState extends ConsumerState<MerchantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMerchantDetails(Map<String, dynamic> m) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final name = m["name"]?.toString() ?? "Merchant";
        final email = m["email"]?.toString() ?? "";
        final phone = m["phone"]?.toString() ?? "";
        final totalDeposits = m["totalDepositsCount"] ?? 0;
        final num usdtVol = (m["totalUsdtDeposited"] as num?) ?? 0;
        final kyc = m["kycStatus"]?.toString() ?? "verified";

        return Padding(
          padding: const EdgeInsets.all(24.0),
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
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.appleBlue.withValues(alpha: 0.15),
                    child: Text(
                      name.isNotEmpty ? name.substring(0, 1).toUpperCase() : "M",
                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.appleBlue, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        Text(email, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.mintGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(kyc.toUpperCase(), style: const TextStyle(color: AppTheme.mintGreen, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(bgColor: AppTheme.cardElevated),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text("Deposited Volume", style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text("$usdtVol USDT", style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(width: 1, height: 28, color: AppTheme.borderSubtle),
                    Column(
                      children: [
                        const Text("Transactions", style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text("$totalDeposits tx", style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text("Phone: $phone", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final merchantsAsync = ref.watch(partnerMerchantsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      appBar: AppBar(
        title: const Text("Merchants"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.mintGreen),
            onPressed: () => ref.invalidate(partnerMerchantsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // iOS Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: "Search referred merchants...",
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),

          Expanded(
            child: merchantsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.mintGreen)),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.warningOrange.withValues(alpha: 0.8)),
                      const SizedBox(height: 14),
                      const Text(
                        "Unable to load merchants",
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Please check server connection or pull down to retry.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 13),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(partnerMerchantsProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text("Retry Now"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.mintGreen,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              data: (merchants) {
                final filtered = merchants.where((m) {
                  final name = (m["name"] ?? "").toString().toLowerCase();
                  final email = (m["email"] ?? "").toString().toLowerCase();
                  return name.contains(_searchQuery) || email.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront_outlined, size: 54, color: AppTheme.textMuted.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        const Text("No merchants found", style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppTheme.mintGreen,
                  backgroundColor: AppTheme.cardSurface,
                  onRefresh: () async => ref.invalidate(partnerMerchantsProvider),
                  child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final m = filtered[i];
                    final name = m["name"]?.toString() ?? "Merchant";
                    final email = m["email"]?.toString() ?? "";
                    final totalDeposits = m["totalDepositsCount"] ?? 0;
                    final num usdtVol = (m["totalUsdtDeposited"] as num?) ?? 0;
                    final dateStr = m["createdAt"] != null ? m["createdAt"].toString().split("T").first : "";

                    return InkWell(
                      onTap: () => _showMerchantDetails(m),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.cardDecoration(),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppTheme.cardElevated,
                              child: Text(
                                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : "M",
                                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.check_circle, size: 14, color: AppTheme.mintGreen),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(email, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                  if (dateStr.isNotEmpty)
                                    Text("Joined $dateStr", style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "$usdtVol USDT",
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "$totalDeposits deposits",
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            ),
          ),
        ],
      ),
    );
  }
}
