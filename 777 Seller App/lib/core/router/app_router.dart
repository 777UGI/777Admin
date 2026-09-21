import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/bank_details/bank_details_screen.dart';
import '../../features/deposit/deposit_screen.dart';
import '../../features/transactions/tracker_screen.dart';
import '../../features/transactions/history_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/profile/profile_screen.dart';

import '../../features/home/main_shell_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (previous, next) {
      notifyListeners();
    });
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) {
          final refCode = state.uri.queryParameters['ref'] ?? state.uri.queryParameters['referralCode'];
          return SignupScreen(initialReferralCode: refCode);
        },
      ),
      ShellRoute(
        builder: (context, state, child) => MainShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/bank-details',
            builder: (context, state) => const BankDetailsScreen(),
          ),
          GoRoute(
            path: '/deposit',
            builder: (context, state) => const DepositScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/tracker/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return TrackerScreen(depositId: id);
        },
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      
      debugPrint('GoRouter redirect - matchedLocation: ${state.matchedLocation}, isInitialized: ${authState.isInitialized}, isLoggedIn: ${authState.user != null}');
      
      if (!authState.isInitialized) {
        return '/splash';
      }

      final isLoggedIn = authState.user != null;
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' || location == '/otp' || location == '/signup';
      final isSplash = location == '/splash';

      if (isSplash) {
        return isLoggedIn ? '/home' : '/login';
      }

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }

      return null;
    },
  );
});
