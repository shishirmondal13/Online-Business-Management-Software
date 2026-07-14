import 'package:flutter_test/flutter_test.dart';
import 'package:smart_buy_online/shared/utils/calculations.dart';

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
        Calculations.calculateSellingPrice(
          productCost: 100,
          profitMargin: 20,
        ),
        120,
      );
    });

    test('parseCurrency handles empty and symbols', () {
      expect(Formatters.parseCurrency(''), 0.0);
      expect(Formatters.parseCurrency('৳1,234.50'), 1234.5);
    });
  });
}
