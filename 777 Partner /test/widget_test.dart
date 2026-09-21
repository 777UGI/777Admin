import "package:flutter_test/flutter_test.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:partner_app_flutter/main.dart";

void main() {
  testWidgets("PartnerApp basic smoke test", (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PartnerApp()));
    expect(find.byType(PartnerApp), findsOneWidget);
  });
}
