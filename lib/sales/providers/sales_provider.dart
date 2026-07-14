import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../shared/constants/firestore_constants.dart';
import '../../shared/services/firestore_helpers.dart';
import '../../auth/providers/auth_provider.dart';

import '../models/sale.dart';
import '../../mobile_sector/models/mobile_stock.dart';
import '../../gadget_sector/models/gadget_stock.dart';
import '../../shared/services/receipt_service.dart';

/// Receipt service provider
final receiptServiceProvider = Provider<ReceiptService>((ref) {
  return ReceiptService();
});

/// Sales list provider (filtered by userId)
final salesListProvider = StreamProvider<List<Sale>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(FirestoreConstants.sales)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => Sale.fromFirestore(doc))
            .toList();
        return list;
      });
});

/// Customers due list provider
final customersDueListProvider = StreamProvider<List<Customer>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(FirestoreConstants.customers)
      .orderBy('remainingDue', descending: true)
      .snapshots()
      .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => Customer.fromFirestore(doc))
            .where((c) => c.remainingDue > 0)
            .toList();
        return list;
      });
});

/// All customers list provider
final allCustomersProvider = StreamProvider<List<Customer>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(FirestoreConstants.customers)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList();
      });
});

/// Customer payments provider
final customerPaymentsProvider = StreamProvider.family<List<Payment>, String>((
  ref,
  customerId,
) {
  return FirebaseFirestore.instance
      .collection(FirestoreConstants.payments)
      .where(FirestoreConstants.customerId, isEqualTo: customerId)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => Payment.fromFirestore(doc))
            .toList();
        return list;
      });
});

/// Global payments provider
final globalPaymentsProvider = StreamProvider<List<Payment>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreConstants.payments)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => Payment.fromFirestore(doc))
            .toList();
      });
});

/// Sales service provider
final salesServiceProvider = Provider<SalesService>((ref) {
  return SalesService();
});

/// Sales service class
class SalesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Create a new sale (sale, customer, payment, capital, and stock in one batch).
  Future<Sale> createSale(Sale sale) async {
    if (sale.sellingPrice <= 0) {
      throw Exception('Selling price must be greater than 0');
    }
    if (sale.paidAmount > sale.totalAmount) {
      throw Exception('Paid amount cannot exceed total sale amount');
    }
    if (sale.dueAmount < 0) {
      throw Exception('Due amount cannot be negative');
    }

    final batch = _firestore.batch();
    final saleId = _uuid.v4();

    // Validate and prepare stock update (read before batch writes).
    if (sale.productType == FirestoreConstants.mobile) {
      final mobileDoc = await _firestore
          .collection(FirestoreConstants.mobileStock)
          .doc(sale.productId)
          .get();
      if (!mobileDoc.exists) {
        throw Exception('Mobile product not found');
      }
      final mobile = MobileStock.fromFirestore(mobileDoc);
      if (mobile.status != FirestoreConstants.unsold) {
        throw Exception('This mobile is already sold');
      }

      final profit = sale.sellingPrice - mobile.netPurchasePrice;
      batch.update(mobileDoc.reference, {
        FirestoreConstants.status: FirestoreConstants.sold,
        FirestoreConstants.soldDate: FieldValue.serverTimestamp(),
        FirestoreConstants.sellingPrice: sale.sellingPrice,
        FirestoreConstants.profit: profit,
        FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
      });
    } else if (sale.productType == FirestoreConstants.gadget) {
      final gadgetDoc = await _firestore
          .collection(FirestoreConstants.gadgetStock)
          .doc(sale.productId)
          .get();
      if (!gadgetDoc.exists) {
        throw Exception('Gadget product not found');
      }
      final gadget = GadgetStock.fromFirestore(gadgetDoc);
      if (sale.quantity > gadget.quantity) {
        throw Exception(
          'Insufficient stock: only ${gadget.quantity} available',
        );
      }

      final newQty = gadget.quantity - sale.quantity;
      batch.update(gadgetDoc.reference, {
        FirestoreConstants.quantity: newQty,
        FirestoreConstants.stockStatus:
            FirestoreHelpers.gadgetStockStatusFromQuantity(newQty),
        FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
      });
    } else {
      throw Exception('Invalid product type');
    }

    // Find or create customer (scoped to userId + contactNumber).
    String customerId;
    if (sale.contactNumber.isNotEmpty) {
      final existingCustomers = await _firestore
          .collection(FirestoreConstants.customers)
          .where(
            FirestoreConstants.contactNumber,
            isEqualTo: sale.contactNumber,
          )
          .limit(1)
          .get();

      if (existingCustomers.docs.isNotEmpty) {
        final existingDoc = existingCustomers.docs.first;
        customerId = existingDoc.id;
        final existing = Customer.fromFirestore(existingDoc);
        final updatedCustomer = existing.copyWith(
          name: sale.customerName.isNotEmpty
              ? sale.customerName
              : existing.name,
          totalDue: existing.totalDue + sale.dueAmount,
          totalPaid: existing.totalPaid + sale.paidAmount,
          remainingDue: existing.remainingDue + sale.dueAmount,
          updatedAt: DateTime.now(),
        );
        batch.update(existingDoc.reference, updatedCustomer.toMap());
      } else {
        customerId = _uuid.v4();
        final customerRef = _firestore
            .collection(FirestoreConstants.customers)
            .doc(customerId);
        batch.set(
          customerRef,
          Customer(
            id: customerId,
            userId: sale.userId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            name: sale.customerName,
            contactNumber: sale.contactNumber,
            totalDue: sale.dueAmount,
            totalPaid: sale.paidAmount,
            remainingDue: sale.dueAmount,
          ).toMap(),
        );
      }
    } else {
      customerId = _uuid.v4();
      final customerRef = _firestore
          .collection(FirestoreConstants.customers)
          .doc(customerId);
      batch.set(
        customerRef,
        Customer(
          id: customerId,
          userId: sale.userId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          name: sale.customerName,
          contactNumber: sale.contactNumber,
          totalDue: sale.dueAmount,
          totalPaid: sale.paidAmount,
          remainingDue: sale.dueAmount,
        ).toMap(),
      );
    }

    final saleRef = _firestore.collection(FirestoreConstants.sales).doc(saleId);
    final newSale = sale.copyWith(id: saleId, customerId: customerId);
    batch.set(saleRef, newSale.toMap());

    if (sale.paidAmount > 0) {
      final paymentId = _uuid.v4();
      final paymentRef = _firestore
          .collection(FirestoreConstants.payments)
          .doc(paymentId);
      batch.set(
        paymentRef,
        Payment(
          id: paymentId,
          userId: sale.userId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          customerId: customerId,
          saleId: saleId,
          date: sale.date,
          amount: sale.paidAmount,
          paymentMethod: 'cash',
          notes: 'Initial payment',
        ).toMap(),
      );

    }

    await batch.commit();
    return newSale;
  }

  /// Add a payment against customer due.
  Future<void> addPayment({
    required String customerId,
    required double amount,
    required String userId,
    String saleId = '',
    String paymentMethod = 'cash',
    String notes = '',
  }) async {
    if (amount <= 0) {
      throw Exception('Payment amount must be greater than 0');
    }

    // Validate payment does not exceed remaining due
    final customerDoc = await _firestore
        .collection(FirestoreConstants.customers)
        .doc(customerId)
        .get();

    if (!customerDoc.exists) {
      throw Exception('Customer not found');
    }

    final customer = Customer.fromFirestore(customerDoc);
    if (amount > customer.remainingDue) {
      throw Exception(
        'Payment amount (৳${amount.toStringAsFixed(2)}) exceeds remaining due (৳${customer.remainingDue.toStringAsFixed(2)})',
      );
    }

    final batch = _firestore.batch();
    final paymentId = _uuid.v4();

    final paymentRef = _firestore
        .collection(FirestoreConstants.payments)
        .doc(paymentId);
    batch.set(
      paymentRef,
      Payment(
        id: paymentId,
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        customerId: customerId,
        saleId: saleId,
        date: DateTime.now(),
        amount: amount,
        paymentMethod: paymentMethod,
        notes: notes,
      ).toMap(),
    );

    final customerRef = _firestore
        .collection(FirestoreConstants.customers)
        .doc(customerId);
    batch.update(customerRef, {
      FirestoreConstants.totalPaid: FieldValue.increment(amount),
      FirestoreConstants.remainingDue: FieldValue.increment(-amount),
      FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
    });



    await batch.commit();
  }
}
