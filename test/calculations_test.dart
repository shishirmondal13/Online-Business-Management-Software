import 'package:flutter_test/flutter_test.dart';
import 'package:smart_buy_online/shared/utils/calculations.dart';
import 'package:smart_buy_online/shared/utils/validators.dart';

void main() {
  group('Calculations', () {
    test('calculateDueAmount rounds correctly', () {
      expect(
        Calculations.calculateDueAmount(totalAmount: 100.0, paidAmount: 33.33),
        66.67,
      );
    });

    test('calculateProfitMargin handles zero cost', () {
      expect(
        Calculations.calculateProfitMargin(sellingPrice: 50, cost: 0),
        100.0,
      );
    });

    test('calculateFinalProfit', () {
      expect(
        Calculations.calculateFinalProfit(
          totalSales: 1000,
          totalCost: 600,
          otherGains: 10,
        ),
        410,
      );
    });

    test('calculateSellingPrice uses margin only', () {
      expect(
        Calculations.calculateSellingPrice(productCost: 100, profitMargin: 20),
        120,
      );
    });

    test('parseCurrency handles empty and symbols', () {
      expect(Formatters.parseCurrency(''), 0.0);
      expect(Formatters.parseCurrency('৳1,234.50'), 1234.5);
    });

    test('quantity rejects zero and negative values', () {
      expect(Validators.quantity('0'), isNotNull);
      expect(Validators.quantity('-1'), isNotNull);
      expect(Validators.quantity('1'), isNull);
    });

    test('date range end is inclusive only through the selected day', () {
      final filter = ReportDateRange(
        fromDate: DateTime(2026, 8, 1),
        toDate: DateTime(2026, 8, 31),
      );

      expect(filter.contains(DateTime(2026, 8, 31, 23, 59, 59)), isTrue);
      expect(filter.contains(DateTime(2026, 9, 1)), isFalse);
    });
  });
}
