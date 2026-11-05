import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_buy_online/dashboard/widgets/dashboard_3d_card.dart';

void main() {
  testWidgets('Dashboard3DCard hover and tap interaction does not crash or vanish', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 220,
              child: Dashboard3DCard(
                title: 'Total Capital',
                value: '৳ 1,234,567.00',
                badgeIcon: Icons.account_balance_wallet_outlined,
                type: Card3DType.totalCapital,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      ),
    );

    // Simulate mouse hover
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(find.byType(Dashboard3DCard)));
    await tester.pumpAndSettle();

    // Verify card is still visible and has children
    expect(find.text('Total Capital'), findsOneWidget);
    expect(find.text('৳ 1,234,567.00'), findsOneWidget);

    // Simulate tap
    await tester.tap(find.byType(Dashboard3DCard));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);

    // Move mouse away
    await gesture.moveTo(Offset.zero);
    await tester.pumpAndSettle();

    expect(find.text('Total Capital'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
