import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "core/theme/theme.dart";
import "features/auth/auth_controller.dart";
import "features/auth/login_screen.dart";
import "features/home/main_shell_screen.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: PartnerApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: "/login",
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == "/login";
      if (!authState.isAuthenticated) {
        return isLoggingIn ? null : "/login";
      }
      if (isLoggingIn) {
        return "/home";
      }
      return null;
    },
    routes: [
      GoRoute(
        path: "/login",
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: "/home",
        builder: (context, state) => const MainShellScreen(),
      ),
    ],
  );
});

class PartnerApp extends ConsumerWidget {
  const PartnerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: "777 Partner VIP",
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
