import 'package:flutter_test/flutter_test.dart';
import 'package:smart_buy_online/mobile_sector/models/mobile_stock.dart';
import 'package:smart_buy_online/gadget_sector/models/gadget_stock.dart';

void main() {
  group('Customer Product Return to Inventory Tests', () {
    test('MobileStock return tracking properties and labels', () {
      final now = DateTime(2026, 8, 29, 20, 0, 0);
      final mobile = MobileStock(
        id: 'mob-001',
        userId: 'user-123',
        createdAt: now,
        updatedAt: now,
        date: now,
        modelName: 'iPhone 15 Pro Max',
        imeiNumber: '356789012345678',
        purchaseRate: 115000.0,
        transportCost: 500.0,
        netPurchasePrice: 115500.0,
        sellingPrice: 128000.0,
        profit: 12500.0,
        status: 'unsold', // Available again in inventory
        isReturned: true,
        returnCount: 1,
        returnReason: 'Customer changed color preference',
        returnedAt: now,
      );

      expect(mobile.isUnsold, isTrue);
      expect(mobile.isReturned, isTrue);
      expect(mobile.returnCount, 1);
      expect(mobile.returnLabel, 'Returned from customer once');

      // Test toMap and fromMap
      final map = mobile.toMap();
      expect(map['isReturned'], isTrue);
      expect(map['returnCount'], 1);
      expect(map['returnReason'], 'Customer changed color preference');
      expect(map['status'], 'unsold');

      final reconstructed = MobileStock.fromMap(map, 'mob-001');
      expect(reconstructed.isReturned, isTrue);
      expect(reconstructed.returnCount, 1);
      expect(reconstructed.returnReason, 'Customer changed color preference');
      expect(reconstructed.status, 'unsold');
      expect(reconstructed.returnLabel, 'Returned from customer once');

      // Test multiple returns
      final multiReturned = reconstructed.copyWith(returnCount: 2);
      expect(multiReturned.returnLabel, 'Returned from customer (2 times)');
    });

    test('GadgetStock return tracking properties and labels', () {
      final now = DateTime(2026, 8, 29, 20, 0, 0);
      final gadget = GadgetStock(
        id: 'gad-001',
        userId: 'user-123',
        createdAt: now,
        updatedAt: now,
        date: now,
        productCode: 'GAD-101',
        productName: 'Apple 20W USB-C Adapter',
        quantity: 15, // Reinstated stock
        purchasePrice: 1800.0,
        transportCost: 50.0,
        packagingCost: 0.0,
        storageCost: 0.0,
        marketingCost: 0.0,
        damageCost: 0.0,
        otherCosts: 0.0,
        productCost: 1850.0,
        profitMargin: 18.9,
        sellingPrice: 2200.0,
        profit: 350.0,
        stockStatus: 'in_stock',
        isReturned: true,
        returnedQuantity: 2,
        returnReason: 'Customer bought incorrect model',
        returnedAt: now,
      );

      expect(gadget.isReturned, isTrue);
      expect(gadget.returnedQuantity, 2);
      expect(gadget.returnLabel, 'Returned from customer (2 pcs)');

      // Test single item return label
      final singleReturn = gadget.copyWith(returnedQuantity: 1);
      expect(singleReturn.returnLabel, 'Returned from customer once');

      // Test toMap and fromMap
      final map = gadget.toMap();
      expect(map['isReturned'], isTrue);
      expect(map['returnedQuantity'], 2);
      expect(map['returnReason'], 'Customer bought incorrect model');

      final reconstructed = GadgetStock.fromMap(map, 'gad-001');
      expect(reconstructed.isReturned, isTrue);
      expect(reconstructed.returnedQuantity, 2);
      expect(reconstructed.returnReason, 'Customer bought incorrect model');
      expect(reconstructed.quantity, 15);
      expect(reconstructed.stockStatus, 'in_stock');
    });
  });
}
