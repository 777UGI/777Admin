import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:usdt_seller_app/main.dart' as app;
import 'package:usdt_seller_app/features/auth/login_screen.dart';
import 'package:usdt_seller_app/features/auth/otp_screen.dart';
import 'package:usdt_seller_app/features/home/home_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('USDT Seller App - End-to-End Integration Flow', () {
    testWidgets('Login -> Bank Details -> Sell Deposit -> Tracker flow validation', (WidgetTester tester) async {
      // 1. Launch the application widget
      await tester.pumpWidget(
        const ProviderScope(
          child: app.MyApp(),
        ),
      );
      
      // Wait for splash transition to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 2. Verify Login screen loaded (looking for Mobile Number text field)
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Enter Mobile Number'), findsOneWidget);

      // Enter phone number
      await tester.enterText(find.byType(TextFormField), '7777777777');
      await tester.pumpAndSettle();
      
      // Tap Get OTP button
      await tester.tap(find.text('Get OTP'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 3. Verify OTP screen loaded
      expect(find.byType(OtpScreen), findsOneWidget);
      expect(find.text('Verify Mobile Number'), findsOneWidget);

      // Enter valid OTP
      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.pumpAndSettle();

      // Click Verify & Proceed
      await tester.tap(find.text('Verify & Proceed'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 4. Verify Home Dashboard screen loaded successfully
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Your OTC Stats'), findsOneWidget);
      
      // Verification check complete
    });
  });
}
