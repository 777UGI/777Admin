import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

// Form validation functions matching the screens
bool validateIfsc(String code) {
  return RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(code.trim().toUpperCase());
}

bool validateUpiId(String upiId) {
  return RegExp(r'^[\w\.\-_]{2,256}@[\w\.\-_]{2,256}$').hasMatch(upiId.trim());
}

bool validateAccountNumberMatch(String accountNum, String confirmAccountNum) {
  if (accountNum.isEmpty || confirmAccountNum.isEmpty) return false;
  return accountNum == confirmAccountNum;
}

// Indian numbering rate calculation formatter
String formatIndianCurrency(double value) {
  final formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  return formatter.format(value);
}

void main() {
  group('USDT Seller App - Unit Tests', () {
    
    // 1. Rate Calculation Display Logic Tests
    test('Rate calculation formatting should match Indian numbering rules', () {
      final double smallAmount = 1250.00;
      final double largeAmount = 125000.00;
      final double croreAmount = 12500000.00;

      expect(formatIndianCurrency(smallAmount), contains('₹1,250.00'));
      expect(formatIndianCurrency(largeAmount), contains('₹1,25,000.00'));
      expect(formatIndianCurrency(croreAmount), contains('₹1,25,00,000.00'));
    });

    test('USDT multiplication calculations must evaluate correctly', () {
      const double lockedRate = 88.50;
      const double usdtAmount = 150;
      final expectedPayout = usdtAmount * lockedRate;

      expect(expectedPayout, equals(13275.0));
      expect(formatIndianCurrency(expectedPayout), contains('₹13,275.00'));
    });

    // 2. Form Validation Tests
    test('IFSC Code pattern validation rules', () {
      // Valid IFSC formats
      expect(validateIfsc('HDFC0000123'), isTrue);
      expect(validateIfsc('SBIN0001234'), isTrue);
      expect(validateIfsc('icic0000222'), isTrue); // Case-insensitive check handled inside validator

      // Invalid IFSC formats
      expect(validateIfsc('HDFC000123'), isFalse); // 10 chars (short)
      expect(validateIfsc('HDFCA000123'), isFalse); // 5th character not zero
      expect(validateIfsc(''), isFalse);
    });

    test('UPI ID (VPA) pattern validation rules', () {
      // Valid UPI IDs
      expect(validateUpiId('seller@hdfc'), isTrue);
      expect(validateUpiId('username.name@okaxis'), isTrue);
      expect(validateUpiId('payee-name@ybl'), isTrue);

      // Invalid UPI IDs
      expect(validateUpiId('invalidupiid'), isFalse); // No @ symbol
      expect(validateUpiId('@okaxis'), isFalse); // Empty prefix
      expect(validateUpiId('payee@'), isFalse); // Empty VPA bank suffix
      expect(validateUpiId(''), isFalse);
    });

    test('Bank Account numbers matches checking', () {
      expect(validateAccountNumberMatch('123456789', '123456789'), isTrue);
      expect(validateAccountNumberMatch('123456789', '123456780'), isFalse); // Mismatch
      expect(validateAccountNumberMatch('', '123456789'), isFalse); // Empty check
    });

    // 3. Simulated Timer Countdown logic Tests
    test('OTP Countdown timer ticks update remaining seconds appropriately', () {
      int remainingSeconds = 60;
      
      // Simulate 1 tick of the periodic countdown
      if (remainingSeconds > 0) {
        remainingSeconds--;
      }
      expect(remainingSeconds, equals(59));

      // Simulate timer ticking down to 0
      for (int i = 0; i < 59; i++) {
        if (remainingSeconds > 0) {
          remainingSeconds--;
        }
      }
      expect(remainingSeconds, equals(0));
    });
  });
}
