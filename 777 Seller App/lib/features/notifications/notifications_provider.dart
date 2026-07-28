import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String timestamp;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      body: body,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationsNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationsNotifier() : super([]) {
    _loadMockNotifications();
    _initializeFCM();
  }

  void _loadMockNotifications() {
    state = [
      NotificationItem(
        id: '1',
        title: 'INR Payout Sent 🏦',
        body:
            'Payout of ₹44,250.00 for Deposit ID cf35ebd1 has been processed. UTR Ref: UTR_MOCK_112233.',
        timestamp: '2026-07-18T14:30:00Z',
      ),
      NotificationItem(
        id: '2',
        title: 'USDT Deposit Verified ✅',
        body:
            'Your deposit of 500.00 USDT on TRC20 has been verified by the compliance desk.',
        timestamp: '2026-07-18T14:15:00Z',
      ),
      NotificationItem(
        id: '3',
        title: 'KYC Verification Approved 🎉',
        body:
            'Congratulations! Your PAN and Aadhaar identity documents have been approved. Deposit tools unlocked.',
        timestamp: '2026-07-18T12:00:00Z',
      ),
    ];
  }

  void _initializeFCM() {
    // Simulated Firebase Cloud Messaging registration and listeners
    // In full production, this maps to:
    // FirebaseMessaging.instance.getToken().then((token) => saveTokenToBackend(token));
    // FirebaseMessaging.onMessage.listen((RemoteMessage message) { addNotification(message); });
  }

  void markAsRead(String id) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();
  }

  void markAllAsRead() {
    state = state.map((item) => item.copyWith(isRead: true)).toList();
  }
}

final notificationsNotifierProvider =
    StateNotifierProvider<NotificationsNotifier, List<NotificationItem>>((ref) {
      return NotificationsNotifier();
    });
