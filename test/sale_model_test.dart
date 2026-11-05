import 'package:flutter_test/flutter_test.dart';
import 'package:smart_buy_online/sales/models/sale.dart';

void main() {
  group('Sale.create', () {
    test('computes totals and payment status', () {
      final sale = Sale.create(
        userId: 'user1',
        date: DateTime(2025, 1, 1),
        productType: 'gadget',
        productId: 'p1',
        productName: 'Case',
        quantity: 2,
        sellingPrice: 100,
        customerId: '',
        customerName: 'Ali',
        contactNumber: '01700000000',
        paidAmount: 100,
        profit: 40,
      );

      expect(sale.totalAmount, 200);
      expect(sale.dueAmount, 100);
      expect(sale.paymentStatus, 'partial');
    });

    test('marks fully paid sales', () {
      final sale = Sale.create(
        userId: 'user1',
        date: DateTime(2025, 1, 1),
        productType: 'mobile',
        productId: 'p1',
        productName: 'Phone',
        quantity: 1,
        sellingPrice: 500,
        customerId: '',
        customerName: 'Ali',
        contactNumber: '',
        paidAmount: 500,
        profit: 50,
      );

      expect(sale.paymentStatus, 'paid');
      expect(sale.dueAmount, 0);
    });

    test('stores and serializes sale notes properly', () {
      final sale = Sale.create(
        userId: 'user1',
        date: DateTime(2025, 1, 1),
        productType: 'gadget',
        productId: 'p1',
        productName: 'Case',
        quantity: 1,
        sellingPrice: 100,
        customerId: 'c1',
        customerName: 'Ali',
        contactNumber: '01700000000',
        paidAmount: 100,
        profit: 40,
        notes: '1 Year Warranty Included',
      );

      expect(sale.notes, '1 Year Warranty Included');
      final map = sale.toMap();
      expect(map['notes'], '1 Year Warranty Included');

      final fromMap = Sale.fromMap(map, 'sale-1');
      expect(fromMap.notes, '1 Year Warranty Included');
    });

    test('rejects invalid financial invariants', () {
      expect(
        () => Sale.create(
          userId: 'user1',
          date: DateTime(2025, 1, 1),
          productType: 'gadget',
          productId: 'p1',
          productName: 'Case',
          quantity: 0,
          sellingPrice: 100,
          customerId: '',
          customerName: 'Ali',
          contactNumber: '',
          paidAmount: 0,
          profit: 0,
        ),
        throwsArgumentError,
      );
    });
  });
}
