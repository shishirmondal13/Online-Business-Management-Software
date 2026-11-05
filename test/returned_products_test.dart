import 'package:flutter_test/flutter_test.dart';
import 'package:smart_buy_online/dashboard/providers/dashboard_provider.dart';
import 'package:smart_buy_online/mobile_sector/models/mobile_stock.dart';
import 'package:smart_buy_online/gadget_sector/models/gadget_stock.dart';

void main() {
  group('Dashboard Returned & Damaged Products Tests', () {
    test('DashboardData initializes with returned and damaged products metrics', () {
      const data = DashboardData(
        mobileReturnedCount: 3,
        gadgetReturnedQuantity: 7,
        mobileReturnedValue: 350000.0,
        gadgetReturnedValue: 14000.0,
        mobileDamagedCount: 2,
        mobileDamagedValue: 200000.0,
        gadgetDamagedQuantity: 4,
        gadgetDamagedValue: 8000.0,
      );

      expect(data.mobileReturnedCount, 3);
      expect(data.gadgetReturnedQuantity, 7);
      expect(data.mobileReturnedValue, 350000.0);
      expect(data.gadgetReturnedValue, 14000.0);
      expect(data.mobileDamagedCount, 2);
      expect(data.mobileDamagedValue, 200000.0);
      expect(data.gadgetDamagedQuantity, 4);
      expect(data.gadgetDamagedValue, 8000.0);
      expect(data.totalDamageLoss, 208000.0);
    });

    test('Mobile and Gadget return & damage detection logic', () {
      final now = DateTime(2026, 8, 29);
      final mobiles = [
        MobileStock(
          id: 'mob-1',
          userId: 'u1',
          createdAt: now,
          updatedAt: now,
          date: now,
          modelName: 'iPhone 15 Pro',
          imeiNumber: '356789012345678',
          purchaseRate: 110000,
          transportCost: 500,
          netPurchasePrice: 110500,
          sellingPrice: 125000,
          profit: 14500,
          status: 'unsold',
          isReturned: true,
          returnCount: 1,
        ),
        MobileStock(
          id: 'mob-2',
          userId: 'u1',
          createdAt: now,
          updatedAt: now,
          date: now,
          modelName: 'Galaxy S24',
          imeiNumber: '356789012345679',
          purchaseRate: 90000,
          transportCost: 500,
          netPurchasePrice: 90500,
          sellingPrice: 102000,
          profit: 11500,
          status: 'damaged',
          damageReason: 'Water damaged display',
          isReturned: false,
          returnCount: 0,
        ),
      ];

      final returnedMobiles = mobiles.where((m) => m.isReturned || m.returnCount > 0).toList();
      expect(returnedMobiles.length, 1);
      expect(returnedMobiles.first.modelName, 'iPhone 15 Pro');

      final damagedMobiles = mobiles.where((m) => m.status == 'damaged' || m.isDamaged).toList();
      expect(damagedMobiles.length, 1);
      expect(damagedMobiles.first.modelName, 'Galaxy S24');

      final gadgets = [
        GadgetStock(
          id: 'gad-1',
          userId: 'u1',
          createdAt: now,
          updatedAt: now,
          date: now,
          productCode: 'GAD-01',
          productName: 'AirPods Pro',
          quantity: 8,
          purchasePrice: 18000,
          transportCost: 100,
          packagingCost: 0,
          storageCost: 0,
          marketingCost: 0,
          damageCost: 0,
          otherCosts: 0,
          productCost: 18100,
          profitMargin: 20,
          sellingPrice: 21720,
          profit: 3620,
          stockStatus: 'in_stock',
          isReturned: true,
          returnedQuantity: 2,
          damagedQuantity: 1,
          damageValue: 18100,
        ),
        GadgetStock(
          id: 'gad-2',
          userId: 'u1',
          createdAt: now,
          updatedAt: now,
          date: now,
          productCode: 'GAD-02',
          productName: 'Power Bank 20000mAh',
          quantity: 12,
          purchasePrice: 2200,
          transportCost: 50,
          packagingCost: 0,
          storageCost: 0,
          marketingCost: 0,
          damageCost: 0,
          otherCosts: 0,
          productCost: 2250,
          profitMargin: 25,
          sellingPrice: 2812.5,
          profit: 562.5,
          stockStatus: 'in_stock',
          isReturned: false,
          returnedQuantity: 0,
          damagedQuantity: 0,
        ),
      ];

      final returnedGadgets = gadgets.where((g) => g.isReturned || g.returnedQuantity > 0).toList();
      expect(returnedGadgets.length, 1);
      expect(returnedGadgets.first.returnedQuantity, 2);

      final damagedGadgets = gadgets.where((g) => g.damagedQuantity > 0).toList();
      expect(damagedGadgets.length, 1);
      expect(damagedGadgets.first.damagedQuantity, 1);
    });
  });
}
