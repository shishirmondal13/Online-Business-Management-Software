import 'package:flutter_test/flutter_test.dart';
import 'package:smart_buy_online/returns/models/damage_event.dart';
import 'package:smart_buy_online/mobile_sector/models/mobile_stock.dart';
import 'package:smart_buy_online/gadget_sector/models/gadget_stock.dart';

void main() {
  group('DamageEvent Model', () {
    test('DamageEvent fromMap and toMap serializes properly', () {
      final now = DateTime(2026, 8, 29, 14, 0, 0);
      final event = DamageEvent(
        id: 'dmg-123',
        userId: 'user-1',
        createdAt: now,
        updatedAt: now,
        productType: 'mobile',
        productId: 'mob-1',
        productName: 'iPhone 15 Pro',
        identifier: '356789012345678',
        quantity: 1,
        unitCost: 120000.0,
        damageValue: 120000.0,
        reason: 'Broken screen and bent frame',
        date: now,
      );

      final map = event.toMap();
      expect(map['productType'], 'mobile');
      expect(map['productId'], 'mob-1');
      expect(map['productName'], 'iPhone 15 Pro');
      expect(map['identifier'], '356789012345678');
      expect(map['quantity'], 1);
      expect(map['unitCost'], 120000.0);
      expect(map['damageValue'], 120000.0);
      expect(map['reason'], 'Broken screen and bent frame');

      final reconstructed = DamageEvent.fromMap(map, 'dmg-123');
      expect(reconstructed.id, 'dmg-123');
      expect(reconstructed.productType, 'mobile');
      expect(reconstructed.isMobile, isTrue);
      expect(reconstructed.isGadget, isFalse);
      expect(reconstructed.productName, 'iPhone 15 Pro');
      expect(reconstructed.identifier, '356789012345678');
      expect(reconstructed.quantity, 1);
      expect(reconstructed.damageValue, 120000.0);
    });

    test('Gadget DamageEvent computes multi-unit total damage loss', () {
      final now = DateTime(2026, 8, 29);
      final event = DamageEvent(
        id: 'dmg-gadget-1',
        userId: 'user-1',
        createdAt: now,
        updatedAt: now,
        productType: 'gadget',
        productId: 'gadget-1',
        productName: 'AirPods Pro 2',
        identifier: 'APP2-001',
        quantity: 3,
        unitCost: 18000.0,
        damageValue: 54000.0, // 3 * 18000
        reason: 'Water damaged packaging during heavy rain',
        date: now,
      );

      expect(event.isGadget, isTrue);
      expect(event.isMobile, isFalse);
      expect(event.damageValue, event.unitCost * event.quantity);
    });

    test('Mobile stock damage status transition and deduction', () {
      final now = DateTime.now();
      final mobile = MobileStock.create(
        userId: 'user-1',
        date: now,
        modelName: 'Samsung S24 Ultra',
        imeiNumber: '998877665544332',
        purchaseRate: 115000,
        transportCost: 500,
        sellingPrice: 130000,
      );

      expect(mobile.isUnsold, isTrue);
      expect(mobile.isDamaged, isFalse);

      // Transition to damaged
      final damagedMobile = mobile.copyWith(
        status: 'damaged',
        damageReason: 'Display dead pixels on unboxing',
      );

      expect(damagedMobile.isUnsold, isFalse);
      expect(damagedMobile.isDamaged, isTrue);
      expect(damagedMobile.damageReason, 'Display dead pixels on unboxing');
      expect(damagedMobile.netPurchasePrice, 115500);
    });

    test('Gadget stock damage quantity reduction and damage cost tracking', () {
      final now = DateTime.now();
      final gadget = GadgetStock.create(
        userId: 'user-1',
        date: now,
        productCode: 'ANKER-737',
        productName: 'Anker 737 Power Bank',
        quantity: 10,
        purchasePrice: 9000,
        transportCost: 200,
        profitMargin: 20,
      );

      expect(gadget.quantity, 10);
      expect(gadget.damagedQuantity, 0);
      expect(gadget.damageValue, 0.0);
      expect(gadget.stockStatus, 'in_stock');

      // 2 units damaged
      const damagedQty = 2;
      final damageCost = gadget.productCost * damagedQty;
      final remainingQty = gadget.quantity - damagedQty;

      final updatedGadget = gadget.copyWith(
        quantity: remainingQty,
        damagedQuantity: gadget.damagedQuantity + damagedQty,
        damageValue: gadget.damageValue + damageCost,
      );

      expect(updatedGadget.quantity, 8);
      expect(updatedGadget.damagedQuantity, 2);
      expect(updatedGadget.damageValue, 18400.0);
    });
  });
}
