import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_buy_online/dashboard/widgets/dashboard_3d_card.dart';

void main() {
  testWidgets('Dashboard3DCard in GridView at various screen sizes', (tester) async {
    FlutterError.onError = (details) {
      FlutterError.dumpErrorToConsole(details);
    };

    final sizes = [
      const Size(1920, 1080),
      const Size(1366, 768),
      const Size(1024, 768),
      const Size(800, 600),
      const Size(500, 800),
    ];

    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                childAspectRatio: 1.34,
                children: [
                  Dashboard3DCard(
                    title: 'Total Capital',
                    value: '৳ 3,034.00',
                    badgeIcon: Icons.account_balance_wallet_outlined,
                    type: Card3DType.totalCapital,
                  ),
                  Dashboard3DCard(
                    title: 'Available Capital',
                    value: '৳ 1,980.00',
                    badgeIcon: Icons.savings_outlined,
                    type: Card3DType.availableCapital,
                  ),
                  Dashboard3DCard(
                    title: 'Total Investment',
                    value: '৳ 3,000.00',
                    badgeIcon: Icons.monetization_on_outlined,
                    type: Card3DType.totalInvestment,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
    }
  });
}
