import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(notificationsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgClr = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8F9FA);
    final cardClr = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrim = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final textSec = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final activeGreen = isDark ? const Color(0xFF00E676) : const Color(0xFF0F9D58);
    final unreadBg = isDark ? const Color(0xFF00E676).withOpacity(0.15) : const Color(0xFFE8F5E9);

    return AppScaffold(
      backgroundColor: bgClr,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: bgClr,
        iconTheme: IconThemeData(color: textPrim),
        elevation: 0,
        actions: [
          if (list.any((item) => !item.isRead))
            TextButton(
              onPressed: () => ref.read(notificationsNotifierProvider.notifier).markAllAsRead(),
              child: Text('Mark all read', style: TextStyle(color: activeGreen)),
            ),
        ],
      ),
      body: list.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: textSec.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('All caught up! No notifications.', style: TextStyle(color: textSec, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                final date = DateTime.tryParse(item.timestamp)?.toLocal() ?? DateTime.now();
                final timeAgo = DateFormat('dd MMM, hh:mm a').format(date);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: item.isRead ? cardClr : unreadBg,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => ref.read(notificationsNotifierProvider.notifier).markAsRead(item.id),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            item.title.contains('Sent') || item.title.contains('Paid')
                                ? Icons.account_balance
                                : (item.title.contains('Deposit') ? Icons.savings : Icons.verified_user),
                            color: activeGreen,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                                        color: textPrim,
                                      ),
                                    ),
                                    Text(
                                      timeAgo,
                                      style: TextStyle(fontSize: 10, color: textSec),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.body,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: item.isRead ? textSec : textPrim,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
