import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../core/theme/theme.dart";
import "../dashboard/partner_providers.dart";

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _statusFilter = "all";
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$label copied!"),
        backgroundColor: AppTheme.mintGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(partnerTransactionsProvider);
    final dashboardAsync = ref.watch(partnerDashboardProvider);
    final rates = dashboardAsync.asData?.value["rates"] as Map<String, dynamic>?;
    final double sellingRate = (rates?["sellingRate"] as num?)?.toDouble() ?? 93.5;

    return Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      appBar: AppBar(
        title: const Text("Activity Ledger"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.mintGreen),
            onPressed: () => ref.invalidate(partnerTransactionsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: "Search transactions or tx hash...",
                    prefixIcon: Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFilterChip("All Activity", "all"),
                    const SizedBox(width: 8),
                    _buildFilterChip("Settled", "verified"),
                    const SizedBox(width: 8),
                    _buildFilterChip("Pending", "pending"),
                  ],
                ),
              ],
            ),
          ),

          // Ledger List
          Expanded(
            child: transactionsAsync.when(
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
                        "Unable to load transactions",
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
                        onPressed: () => ref.invalidate(partnerTransactionsProvider),
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
              data: (transactions) {
                final filtered = transactions.where((tx) {
                  final userObj = (tx["userId"] is Map) ? Map<String, dynamic>.from(tx["userId"] as Map) : null;
                  final merchantName = (userObj?["name"] ?? "").toString().toLowerCase();
                  final txHash = (tx["txHash"] ?? "").toString().toLowerCase();
                  final status = (tx["status"] ?? "").toString().toLowerCase();

                  final matchesSearch = merchantName.contains(_searchQuery) || txHash.contains(_searchQuery);
                  if (!matchesSearch) return false;

                  if (_statusFilter == "all") return true;
                  if (_statusFilter == "verified") {
                    return status == "verified" || status == "approved" || status == "paid";
                  }
                  return status == _statusFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_outlined, size: 54, color: AppTheme.textMuted.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        const Text("No transactions found", style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppTheme.mintGreen,
                  backgroundColor: AppTheme.cardSurface,
                  onRefresh: () async => ref.invalidate(partnerTransactionsProvider),
                  child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final tx = filtered[i];
                    final userObj = (tx["userId"] is Map) ? Map<String, dynamic>.from(tx["userId"] as Map) : null;
                    final merchantName = userObj?["name"]?.toString() ?? "Merchant Deposit";
                    final status = tx["status"]?.toString() ?? "pending";
                    final isSettled = status == "verified" || status == "approved" || status == "paid";

                    final num amountUsdt = (tx["amountUsdt"] as num?) ?? 0;
                    final num commUsdt = (tx["commissionAmount"] as num?) ?? 0;
                    final double commInr = commUsdt * sellingRate;
                    final String network = tx["network"]?.toString() ?? "TRC20";
                    final String txHash = tx["txHash"]?.toString() ?? "";
                    final String dateStr = tx["createdAt"] != null ? tx["createdAt"].toString().split("T").first : "";

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.cardDecoration(),
                      child: Row(
                        children: [
                          // Inflow Icon
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.mintGreen.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_downward, color: AppTheme.mintGreen, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  merchantName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cardElevated,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(network, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Dep: $amountUsdt USDT",
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                                if (txHash.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  InkWell(
                                    onTap: () => _copyToClipboard(txHash, "TxHash"),
                                    child: Text(
                                      txHash.length > 14 ? "${txHash.substring(0, 14)}..." : txHash,
                                      style: const TextStyle(color: AppTheme.appleBlue, fontSize: 10),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "+$commUsdt USDT",
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.mintGreen),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "₹${commInr.toStringAsFixed(2)}",
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isSettled ? "SETTLED" : "PENDING",
                                style: TextStyle(
                                  color: isSettled ? AppTheme.mintGreen : AppTheme.warningOrange,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (dateStr.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(dateStr, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                              ],
                            ],
                          ),
                        ],
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.textPrimary : AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.textPrimary : AppTheme.borderSubtle),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppTheme.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
