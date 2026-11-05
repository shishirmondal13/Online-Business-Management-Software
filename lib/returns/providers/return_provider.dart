import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../auth/providers/auth_provider.dart';
import '../../gadget_sector/models/gadget_stock.dart';
import '../../mobile_sector/models/mobile_stock.dart';
import '../../sales/models/sale.dart';
import '../../shared/constants/firestore_constants.dart';
import '../../shared/services/firestore_helpers.dart';
import '../../mobile_sector/providers/mobile_provider.dart';
import '../../gadget_sector/providers/gadget_provider.dart';
import '../models/damage_event.dart';
import '../models/return_transaction.dart';

final returnListProvider = StreamProvider<List<ReturnTransaction>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection(FirestoreConstants.returns)
      .snapshots()
      .map(
        (snapshot) {
          final list = snapshot.docs.map(ReturnTransaction.fromFirestore).toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        },
      );
});

final rawDamageEventsProvider = StreamProvider<List<DamageEvent>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection(FirestoreConstants.damageEvents)
      .snapshots()
      .map(
        (snapshot) {
          final list = snapshot.docs.map(DamageEvent.fromFirestore).toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        },
      );
});

/// Unified damage event list provider combining explicit events, damaged mobile stock, damaged returns, and damaged gadgets
final damageEventListProvider = Provider<AsyncValue<List<DamageEvent>>>((ref) {
  final rawEventsAsync = ref.watch(rawDamageEventsProvider);
  final mobileStockAsync = ref.watch(mobileStockListProvider);
  final gadgetStockAsync = ref.watch(gadgetStockListProvider);
  final returnListAsync = ref.watch(returnListProvider);

  if (rawEventsAsync.isLoading &&
      mobileStockAsync.isLoading &&
      gadgetStockAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final rawEvents = rawEventsAsync.value ?? [];
  final mobileStock = mobileStockAsync.value ?? [];
  final gadgetStock = gadgetStockAsync.value ?? [];
  final returns = returnListAsync.value ?? [];

  final List<DamageEvent> combined = List.from(rawEvents);

  // 1. Synthesize damaged mobile handsets from mobileStock
  for (final mobile in mobileStock) {
    final statusLower = mobile.status.toLowerCase().trim();
    final returnReasonLower = mobile.returnReason.toLowerCase().trim();
    final damageReasonLower = mobile.damageReason.toLowerCase().trim();

    final isDamaged = statusLower == 'damaged' ||
        mobile.isDamaged ||
        damageReasonLower.isNotEmpty ||
        (mobile.isReturned &&
            (returnReasonLower.contains('damage') ||
                returnReasonLower.contains('problem') ||
                returnReasonLower.contains('display') ||
                returnReasonLower.contains('broken') ||
                returnReasonLower.contains('defect') ||
                returnReasonLower.contains('fault') ||
                returnReasonLower.contains('issue')));

    if (isDamaged) {
      final alreadyAdded = combined.any((e) =>
          (e.productId.isNotEmpty && e.productId == mobile.id) ||
          (e.identifier.isNotEmpty &&
              mobile.imeiNumber.isNotEmpty &&
              e.identifier.trim() == mobile.imeiNumber.trim()));

      if (!alreadyAdded) {
        combined.add(DamageEvent(
          id: 'stock_${mobile.id}',
          userId: mobile.userId,
          createdAt: mobile.createdAt,
          updatedAt: mobile.updatedAt,
          productType: 'mobile',
          productId: mobile.id,
          productName: mobile.modelName,
          identifier: mobile.imeiNumber,
          quantity: 1,
          unitCost: mobile.netPurchasePrice,
          damageValue: mobile.netPurchasePrice,
          reason: mobile.damageReason.trim().isNotEmpty
              ? mobile.damageReason.trim()
              : (mobile.returnReason.trim().isNotEmpty
                  ? mobile.returnReason.trim()
                  : 'Damaged Stock'),
          date: mobile.returnedAt ?? mobile.updatedAt,
        ));
      }
    }
  }

  // 2. Synthesize damaged items from Returns
  for (final ret in returns) {
    final condLower = ret.condition.toLowerCase().trim();
    final retReasonLower = ret.reason.toLowerCase().trim();
    final isRetDamaged = condLower == 'damaged' ||
        retReasonLower.contains('damage') ||
        retReasonLower.contains('problem') ||
        retReasonLower.contains('broken') ||
        retReasonLower.contains('defect');

    if (isRetDamaged) {
      final alreadyAdded = combined.any((e) =>
          (e.productId.isNotEmpty && e.productId == ret.productId) ||
          e.id == 'return_${ret.id}');

      if (!alreadyAdded) {
        combined.add(DamageEvent(
          id: 'return_${ret.id}',
          userId: ret.userId,
          createdAt: ret.createdAt,
          updatedAt: ret.updatedAt,
          productType: ret.productType.toLowerCase().trim(),
          productId: ret.productId,
          productName: ret.productName,
          identifier: '',
          quantity: ret.quantity,
          unitCost: ret.unitSalePrice,
          damageValue: ret.refundAmount > 0 ? ret.refundAmount : (ret.unitSalePrice * ret.quantity),
          reason: ret.reason.trim().isNotEmpty ? ret.reason.trim() : 'Returned as Damaged',
          date: ret.date,
        ));
      }
    }
  }

  // 3. Synthesize damaged gadgets with damagedQuantity > 0
  for (final gadget in gadgetStock) {
    if (gadget.damagedQuantity > 0) {
      final alreadyAdded = combined.any((e) =>
          (e.productId.isNotEmpty && e.productId == gadget.id) ||
          (e.identifier.isNotEmpty &&
              gadget.productCode.isNotEmpty &&
              e.identifier.trim() == gadget.productCode.trim()));

      if (!alreadyAdded) {
        combined.add(DamageEvent(
          id: 'gadget_${gadget.id}',
          userId: gadget.userId,
          createdAt: gadget.createdAt,
          updatedAt: gadget.updatedAt,
          productType: 'gadget',
          productId: gadget.id,
          productName: gadget.productName,
          identifier: gadget.productCode,
          quantity: gadget.damagedQuantity,
          unitCost: gadget.productCost,
          damageValue: gadget.damageValue > 0
              ? gadget.damageValue
              : (gadget.productCost * gadget.damagedQuantity),
          reason: 'Damaged Inventory',
          date: gadget.updatedAt,
        ));
      }
    }
  }

  // Sort descending by date
  combined.sort((a, b) => b.date.compareTo(a.date));

  if (rawEventsAsync.hasError && combined.isEmpty) {
    return AsyncValue.error(rawEventsAsync.error!, rawEventsAsync.stackTrace!);
  }

  return AsyncValue.data(combined);
});

final mobileDamageEventsProvider = Provider<AsyncValue<List<DamageEvent>>>((ref) {
  final events = ref.watch(damageEventListProvider);
  return events.whenData((list) => list.where((e) => e.isMobile).toList());
});

final gadgetDamageEventsProvider = Provider<AsyncValue<List<DamageEvent>>>((ref) {
  final events = ref.watch(damageEventListProvider);
  return events.whenData((list) => list.where((e) => e.isGadget).toList());
});

final returnServiceProvider = Provider<ReturnService>((ref) => ReturnService());

class ReturnService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  Future<void> processReturn({
    required String saleId,
    required int quantity,
    required String condition,
    required double refundAmount,
    required String reason,
    required String refundMethod,
    String notes = '',
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw StateError('You must be signed in.');
    if (quantity <= 0) throw ArgumentError('Return quantity must be positive.');
    if (!{'resalable', 'damaged'}.contains(condition)) {
      throw ArgumentError('Invalid return condition.');
    }
    if (refundAmount < 0) throw ArgumentError('Refund cannot be negative.');

    final saleRef = _firestore.collection(FirestoreConstants.sales).doc(saleId);
    final saleDoc = await saleRef.get();
    if (!saleDoc.exists) {
      throw StateError('Sale not found.');
    }
    final sale = Sale.fromFirestore(saleDoc);
    if (sale.userId != userId) {
      throw StateError('Sale belongs to another account.');
    }
    if (sale.returnedQuantity + quantity > sale.quantity) {
      throw StateError(
        'Return quantity exceeds the remaining sale quantity.',
      );
    }
    final maximumRefund = sale.sellingPrice * quantity;
    if (refundAmount > maximumRefund) {
      throw StateError('Refund cannot exceed the returned sale value.');
    }

    final customerRef = _firestore
        .collection(FirestoreConstants.customers)
        .doc(sale.customerId);
    final customerDoc =
        sale.customerId.isEmpty ? null : await customerRef.get();
    final customer = customerDoc != null && customerDoc.exists
        ? Customer.fromFirestore(customerDoc)
        : null;
    final dueReduction = customer == null
        ? 0.0
        : refundAmount.clamp(0.0, customer.remainingDue).toDouble();
    final cashRefund = refundAmount - dueReduction;

    final stockRef = _firestore
        .collection(
          sale.productType == FirestoreConstants.mobile
              ? FirestoreConstants.mobileStock
              : FirestoreConstants.gadgetStock,
        )
        .doc(sale.productId);
    final stockDoc = await stockRef.get();
    if (!stockDoc.exists) throw StateError('Product stock not found.');

    final batch = _firestore.batch();

    double damageUnitCost = 0;
    double damageTotalValue = 0;
    String damageIdentifier = '';

    if (sale.productType == FirestoreConstants.mobile) {
      if (quantity != 1) {
        throw StateError('A mobile return must contain one device.');
      }
      final mobile = MobileStock.fromFirestore(stockDoc);
      if (mobile.userId != userId || mobile.status != FirestoreConstants.sold) {
        throw StateError('This mobile is not available for return.');
      }
      damageUnitCost = mobile.netPurchasePrice;
      damageTotalValue = mobile.netPurchasePrice;
      damageIdentifier = mobile.imeiNumber;

      batch.update(stockRef, {
        FirestoreConstants.status:
            condition == 'damaged' ? 'damaged' : FirestoreConstants.unsold,
        FirestoreConstants.soldDate:
            condition == 'damaged' ? mobile.soldDate : null,
        FirestoreConstants.damageReason: condition == 'damaged' ? reason : '',
        FirestoreConstants.isReturned: true,
        FirestoreConstants.returnCount: mobile.returnCount + 1,
        FirestoreConstants.returnReason: reason,
        FirestoreConstants.returnedAt: FieldValue.serverTimestamp(),
        FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
      });
    } else if (sale.productType == FirestoreConstants.gadget) {
      final gadget = GadgetStock.fromFirestore(stockDoc);
      if (gadget.userId != userId) {
        throw StateError('Product belongs to another account.');
      }
      damageUnitCost = gadget.productCost;
      damageTotalValue = gadget.productCost * quantity;
      damageIdentifier = gadget.productCode;

      final quantityToRestore = condition == 'resalable' ? quantity : 0;
      final newQuantity = gadget.quantity + quantityToRestore;
      final newReturnedQty = gadget.returnedQuantity + quantity;
      batch.update(stockRef, {
        FirestoreConstants.quantity: newQuantity,
        FirestoreConstants.stockStatus:
            FirestoreHelpers.gadgetStockStatusFromQuantity(newQuantity),
        FirestoreConstants.isReturned: true,
        FirestoreConstants.returnedQuantity: newReturnedQty,
        FirestoreConstants.returnReason: reason,
        FirestoreConstants.returnedAt: FieldValue.serverTimestamp(),
        FirestoreConstants.damagedQuantity:
            gadget.damagedQuantity + (condition == 'damaged' ? quantity : 0),
        FirestoreConstants.damageValue: gadget.damageValue +
            (condition == 'damaged' ? gadget.productCost * quantity : 0),
        FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
      });
    } else {
      throw StateError('Invalid product type.');
    }

    if (customer != null) {
      batch.update(
        customerRef,
        customer
            .copyWith(
              totalDue: (customer.totalDue - dueReduction)
                  .clamp(0.0, double.infinity),
              totalPaid: (customer.totalPaid - cashRefund)
                  .clamp(0.0, double.infinity),
              remainingDue: (customer.remainingDue - dueReduction)
                  .clamp(0.0, double.infinity),
              updatedAt: DateTime.now(),
            )
            .toMap(),
      );
    }

    final now = DateTime.now();
    final returnRef =
        _firestore.collection(FirestoreConstants.returns).doc(_uuid.v4());
    batch.set(
      returnRef,
      ReturnTransaction(
        id: returnRef.id,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        date: now,
        saleId: sale.id,
        productType: sale.productType,
        productId: sale.productId,
        productName: sale.productName,
        quantity: quantity,
        unitSalePrice: sale.sellingPrice,
        refundAmount: refundAmount,
        dueReduction: dueReduction,
        cashRefund: cashRefund,
        condition: condition,
        reason: reason,
        customerId: sale.customerId,
        customerName: sale.customerName,
        refundMethod: refundMethod,
        notes: notes,
      ).toMap(),
    );

    if (condition == 'damaged') {
      final damageEventRef = _firestore
          .collection(FirestoreConstants.damageEvents)
          .doc(_uuid.v4());

      batch.set(damageEventRef, {
        'userId': userId,
        'productType': sale.productType,
        'productId': sale.productId,
        'productName': sale.productName,
        'identifier': damageIdentifier,
        'quantity': quantity,
        'unitCost': damageUnitCost,
        'damageValue':
            damageTotalValue > 0 ? damageTotalValue : refundAmount,
        'reason': reason.isNotEmpty
            ? reason
            : 'Returned Damaged from Customer',
        'date': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
    }

    if (cashRefund > 0) {
      final paymentRef =
          _firestore.collection(FirestoreConstants.payments).doc(_uuid.v4());
      batch.set(
        paymentRef,
        Payment(
          id: paymentRef.id,
          userId: userId,
          createdAt: now,
          updatedAt: now,
          customerId: sale.customerId,
          saleId: sale.id,
          date: now,
          amount: -cashRefund,
          paymentMethod: refundMethod,
          notes: 'Product return refund',
        ).toMap(),
      );
    }

    final returnedQuantity = sale.returnedQuantity + quantity;
    final Map<String, dynamic> saleUpdate = {
      FirestoreConstants.returnedQuantity: returnedQuantity,
      FirestoreConstants.returnedAmount: sale.returnedAmount + refundAmount,
      FirestoreConstants.returnStatus:
          returnedQuantity == sale.quantity ? 'full' : 'partial',
      FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
    };

    if (dueReduction > 0) {
      final newDue =
          (sale.dueAmount - dueReduction).clamp(0.0, double.infinity);
      saleUpdate[FirestoreConstants.dueAmount] =
          newDue <= 0.001 ? 0.0 : newDue;
      if (newDue <= 0.001) {
        saleUpdate[FirestoreConstants.paymentStatus] = FirestoreConstants.paid;
      }
    }

    batch.update(saleRef, saleUpdate);

    await batch.commit();
  }

  Future<void> recordDamage({
    required String productType,
    required String productId,
    required int quantity,
    required String reason,
    DateTime? date,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw StateError('You must be signed in.');
    if (quantity <= 0 || reason.trim().isEmpty) {
      throw ArgumentError('Quantity and damage reason are required.');
    }

    final collection = productType == FirestoreConstants.mobile
        ? FirestoreConstants.mobileStock
        : FirestoreConstants.gadgetStock;
    final stockRef = _firestore.collection(collection).doc(productId);
    final stockDoc = await stockRef.get();
    if (!stockDoc.exists) throw StateError('Product stock not found.');

    final now = DateTime.now();
    final eventDate = date ?? now;
    double damageValue = 0;
    double unitCost = 0;
    String productName = '';
    String identifier = '';
    Map<String, dynamic> stockUpdate = {};

    if (productType == FirestoreConstants.mobile) {
      final mobile = MobileStock.fromFirestore(stockDoc);
      if (mobile.userId != userId || !mobile.isUnsold || quantity != 1) {
        throw StateError('Only one unsold mobile can be marked damaged.');
      }
      unitCost = mobile.netPurchasePrice;
      damageValue = mobile.netPurchasePrice;
      productName = mobile.modelName;
      identifier = mobile.imeiNumber;

      stockUpdate = {
        FirestoreConstants.status: 'damaged',
        FirestoreConstants.damageReason: reason.trim(),
        FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
      };
    } else if (productType == FirestoreConstants.gadget) {
      final gadget = GadgetStock.fromFirestore(stockDoc);
      if (gadget.userId != userId || quantity > gadget.quantity) {
        throw StateError('Damage quantity exceeds available stock.');
      }
      unitCost = gadget.productCost;
      damageValue = gadget.productCost * quantity;
      productName = gadget.productName;
      identifier = gadget.productCode;

      final newQuantity = gadget.quantity - quantity;
      stockUpdate = {
        FirestoreConstants.quantity: newQuantity,
        FirestoreConstants.stockStatus:
            FirestoreHelpers.gadgetStockStatusFromQuantity(newQuantity),
        FirestoreConstants.damagedQuantity: gadget.damagedQuantity + quantity,
        FirestoreConstants.damageValue: gadget.damageValue + damageValue,
        FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
      };
    } else {
      throw StateError('Invalid product type.');
    }

    final eventRef = _firestore
        .collection(FirestoreConstants.damageEvents)
        .doc(_uuid.v4());

    final batch = _firestore.batch();
    batch.update(stockRef, stockUpdate);
    batch.set(eventRef, {
      'userId': userId,
      'productType': productType,
      'productId': productId,
      'productName': productName,
      'identifier': identifier,
      'quantity': quantity,
      'unitCost': unitCost,
      'damageValue': damageValue,
      'reason': reason.trim(),
      'date': Timestamp.fromDate(eventDate),
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    await batch.commit();
  }

  /// Scans mobile_stock and returns for any damaged items missing from damage_events collection and persists them to Firestore.
  Future<int> syncMissingDamageEvents() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 0;

    int syncedCount = 0;
    try {
      final existingEventsSnapshot = await _firestore
          .collection(FirestoreConstants.damageEvents)
          .where(FirestoreConstants.userId, isEqualTo: userId)
          .get();

      final existingProductIds = existingEventsSnapshot.docs
          .map((d) => (d.data()['productId'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();

      final existingIdentifiers = existingEventsSnapshot.docs
          .map((d) => (d.data()['identifier'] ?? '').toString().trim())
          .where((id) => id.isNotEmpty)
          .toSet();

      final batch = _firestore.batch();

      // 1. Sync from mobile_stock
      final mobileSnapshot = await _firestore
          .collection(FirestoreConstants.mobileStock)
          .where(FirestoreConstants.userId, isEqualTo: userId)
          .get();

      for (final doc in mobileSnapshot.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase().trim();
        final isDamaged = status == 'damaged';
        final isReturned =
            data['isReturned'] == true || (data['returnCount'] ?? 0) > 0;
        final returnReason =
            (data['returnReason'] ?? '').toString().toLowerCase().trim();
        final damageReason = (data['damageReason'] ?? '').toString().trim();
        final imei = (data['imeiNumber'] ?? '').toString().trim();

        final shouldSync = isDamaged ||
            damageReason.isNotEmpty ||
            (isReturned &&
                (returnReason.contains('damage') ||
                    returnReason.contains('problem') ||
                    returnReason.contains('display') ||
                    returnReason.contains('broken') ||
                    returnReason.contains('defect') ||
                    returnReason.contains('fault') ||
                    returnReason.contains('issue')));

        if (shouldSync) {
          if (!existingProductIds.contains(doc.id) &&
              (imei.isEmpty || !existingIdentifiers.contains(imei))) {
            final newEventRef = _firestore
                .collection(FirestoreConstants.damageEvents)
                .doc(_uuid.v4());

            final unitCost = (data['netPurchasePrice'] ??
                    data['purchaseRate'] ??
                    0.0)
                .toDouble();
            final now = DateTime.now();
            final itemDate = data['returnedAt'] ??
                data['date'] ??
                Timestamp.fromDate(now);

            batch.set(newEventRef, {
              'userId': userId,
              'productType': 'mobile',
              'productId': doc.id,
              'productName': data['modelName'] ?? 'Mobile Handset',
              'identifier': imei,
              'quantity': 1,
              'unitCost': unitCost,
              'damageValue': unitCost,
              'reason': damageReason.isNotEmpty
                  ? damageReason
                  : ((data['returnReason']?.toString().isNotEmpty == true)
                      ? data['returnReason']
                      : 'Display problem'),
              'date': itemDate,
              'createdAt': Timestamp.fromDate(now),
              'updatedAt': Timestamp.fromDate(now),
            });
            existingProductIds.add(doc.id);
            if (imei.isNotEmpty) existingIdentifiers.add(imei);
            syncedCount++;
          }
        }
      }

      // 2. Sync from returns
      final returnsSnapshot = await _firestore
          .collection(FirestoreConstants.returns)
          .where(FirestoreConstants.userId, isEqualTo: userId)
          .get();

      for (final doc in returnsSnapshot.docs) {
        final data = doc.data();
        final condition =
            (data['condition'] ?? '').toString().toLowerCase().trim();
        final reason = (data['reason'] ?? '').toString().trim();
        final isDamaged = condition == 'damaged' ||
            reason.toLowerCase().contains('problem') ||
            reason.toLowerCase().contains('damage') ||
            reason.toLowerCase().contains('broken') ||
            reason.toLowerCase().contains('display');

        final productId = (data['productId'] ?? '').toString();

        if (isDamaged &&
            !existingProductIds.contains(productId) &&
            !existingProductIds.contains(doc.id)) {
          final newEventRef = _firestore
              .collection(FirestoreConstants.damageEvents)
              .doc(_uuid.v4());

          final refundAmount = (data['refundAmount'] ?? 0.0).toDouble();
          final unitPrice = (data['unitSalePrice'] ?? 0.0).toDouble();
          final qty = (data['quantity'] ?? 1).toInt();
          final now = DateTime.now();

          batch.set(newEventRef, {
            'userId': userId,
            'productType': (data['productType'] ?? 'mobile')
                .toString()
                .toLowerCase()
                .trim(),
            'productId': productId.isNotEmpty ? productId : doc.id,
            'productName': data['productName'] ?? 'Returned Item',
            'identifier': '',
            'quantity': qty,
            'unitCost': unitPrice,
            'damageValue':
                refundAmount > 0 ? refundAmount : (unitPrice * qty),
            'reason': reason.isNotEmpty ? reason : 'Returned as Damaged',
            'date': data['date'] ?? Timestamp.fromDate(now),
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          });
          existingProductIds.add(productId);
          existingProductIds.add(doc.id);
          syncedCount++;
        }
      }

      if (syncedCount > 0) {
        await batch.commit();
      }
    } catch (_) {}
    return syncedCount;
  }
}
