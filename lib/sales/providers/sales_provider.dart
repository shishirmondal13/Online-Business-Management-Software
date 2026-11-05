import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

/// Sales list provider (shared store sales)
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

/// Single customer provider for real-time due tracking
final singleCustomerProvider = StreamProvider.family<Customer?, String>((
  ref,
  customerId,
) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null || customerId.isEmpty) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection(FirestoreConstants.customers)
      .doc(customerId)
      .snapshots()
      .map((doc) => doc.exists ? Customer.fromFirestore(doc) : null);
});

/// Customer payments provider
final customerPaymentsProvider = StreamProvider.family<List<Payment>, String>((
  ref,
  customerId,
) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

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
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection(FirestoreConstants.payments)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();
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
    final authenticatedUserId = FirebaseAuth.instance.currentUser?.uid;
    if (authenticatedUserId == null || sale.userId != authenticatedUserId) {
      throw Exception('Authenticated user does not match sale owner');
    }
    if (sale.quantity <= 0) {
      throw Exception('Quantity must be greater than 0');
    }
    if (sale.paidAmount < 0) {
      throw Exception('Paid amount cannot be negative');
    }
    if (sale.productType == FirestoreConstants.mobile && sale.quantity != 1) {
      throw Exception('A mobile sale must contain exactly one device');
    }
    if (sale.sellingPrice <= 0) {
      throw Exception('Selling price must be greater than 0');
    }
    if (sale.paidAmount > sale.totalAmount) {
      throw Exception('Paid amount cannot exceed total sale amount');
    }
    if (sale.dueAmount < 0) {
      throw Exception('Due amount cannot be negative');
    }

    final saleId = _uuid.v4();
    DocumentReference<Map<String, dynamic>>? existingCustomerRef;
    if (sale.contactNumber.isNotEmpty) {
      final existingCustomers = await _firestore
          .collection(FirestoreConstants.customers)
          .where(FirestoreConstants.userId, isEqualTo: sale.userId)
          .where(
            FirestoreConstants.contactNumber,
            isEqualTo: sale.contactNumber,
          )
          .limit(1)
          .get();
      if (existingCustomers.docs.isNotEmpty) {
        existingCustomerRef = existingCustomers.docs.first.reference;
      }
    }
    DocumentReference<Map<String, dynamic>> stockRef;
    Map<String, dynamic> stockUpdate;
    if (sale.productType == FirestoreConstants.mobile) {
      final mobileRef = _firestore
          .collection(FirestoreConstants.mobileStock)
          .doc(sale.productId);
      final mobileDoc = await mobileRef.get();
      if (!mobileDoc.exists) throw Exception('Mobile product not found');
      final mobile = MobileStock.fromFirestore(mobileDoc);
      if (mobile.userId != sale.userId ||
          mobile.status != FirestoreConstants.unsold) {
        throw Exception('This mobile is unavailable');
      }
      stockRef = mobileRef;
      stockUpdate = {
        FirestoreConstants.status: FirestoreConstants.sold,
        FirestoreConstants.soldDate: FieldValue.serverTimestamp(),
        FirestoreConstants.sellingPrice: sale.sellingPrice,
        FirestoreConstants.profit: sale.sellingPrice - mobile.netPurchasePrice,
        FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
      };
    } else if (sale.productType == FirestoreConstants.gadget) {
      final gadgetRef = _firestore
          .collection(FirestoreConstants.gadgetStock)
          .doc(sale.productId);
      final gadgetDoc = await gadgetRef.get();
      if (!gadgetDoc.exists) throw Exception('Gadget product not found');
      final gadget = GadgetStock.fromFirestore(gadgetDoc);
      if (gadget.userId != sale.userId || sale.quantity > gadget.quantity) {
        throw Exception('Insufficient stock');
      }
      final newQty = gadget.quantity - sale.quantity;
      stockRef = gadgetRef;
      stockUpdate = {
        FirestoreConstants.quantity: newQty,
        FirestoreConstants.stockStatus:
            FirestoreHelpers.gadgetStockStatusFromQuantity(newQty),
        FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
      };
    } else {
      throw Exception('Invalid product type');
    }

    final customerRef =
        existingCustomerRef ??
        _firestore
            .collection(FirestoreConstants.customers)
            .doc(
              sale.contactNumber.isEmpty
                  ? _uuid.v4()
                  : '${sale.userId}_${Uri.encodeComponent(sale.contactNumber)}',
            );
    final customerDoc = await customerRef.get();
    final existing = customerDoc.exists
        ? Customer.fromFirestore(customerDoc)
        : null;
    final customerId = customerRef.id;
    final now = DateTime.now();

    // Use a write batch after validation reads. This is supported reliably by
    // the Windows Firestore plugin and still commits all sale-related writes
    // atomically. Firestore rules enforce ownership on every write.
    final batch = _firestore.batch();
    batch.update(stockRef, stockUpdate);
    if (existing != null) {
      batch.update(
        customerRef,
        existing
            .copyWith(
              name: sale.customerName.isNotEmpty
                  ? sale.customerName
                  : existing.name,
              totalDue: existing.totalDue + sale.dueAmount,
              totalPaid: existing.totalPaid + sale.paidAmount,
              remainingDue: existing.remainingDue + sale.dueAmount,
              updatedAt: now,
            )
            .toMap(),
      );
    } else {
      batch.set(
        customerRef,
        Customer(
          id: customerId,
          userId: sale.userId,
          createdAt: now,
          updatedAt: now,
          name: sale.customerName,
          contactNumber: sale.contactNumber,
          totalDue: sale.dueAmount,
          totalPaid: sale.paidAmount,
          remainingDue: sale.dueAmount,
        ).toMap(),
      );
    }

    final newSale = sale.copyWith(
      id: saleId,
      customerId: customerId,
      createdAt: now,
      updatedAt: now,
    );
    batch.set(
      _firestore.collection(FirestoreConstants.sales).doc(saleId),
      newSale.toMap(),
    );
    if (sale.paidAmount > 0) {
      final paymentId = _uuid.v4();
      batch.set(
        _firestore.collection(FirestoreConstants.payments).doc(paymentId),
        Payment(
          id: paymentId,
          userId: sale.userId,
          createdAt: now,
          updatedAt: now,
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

  /// Add a payment against customer due and update sale status to 'paid' when due is cleared.
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
    if (FirebaseAuth.instance.currentUser?.uid != userId) {
      throw Exception('Authenticated user does not match payment owner');
    }

    final customerRef =
        _firestore.collection(FirestoreConstants.customers).doc(customerId);
    final customerDoc = await customerRef.get();
    if (!customerDoc.exists) {
      throw Exception('Customer not found');
    }
    final customer = Customer.fromFirestore(customerDoc);
    if (customer.userId != userId) {
      throw Exception('Customer does not belong to this account');
    }
    if (amount > customer.remainingDue + 0.05) {
      throw Exception(
        'Payment amount (৳${amount.toStringAsFixed(2)}) exceeds remaining due (৳${customer.remainingDue.toStringAsFixed(2)})',
      );
    }
    final now = DateTime.now();
    final paymentId = _uuid.v4();
    final batch = _firestore.batch();

    // 1. Record the Payment
    batch.set(
      _firestore.collection(FirestoreConstants.payments).doc(paymentId),
      Payment(
        id: paymentId,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        customerId: customerId,
        saleId: saleId,
        date: now,
        amount: amount,
        paymentMethod: paymentMethod,
        notes: notes,
      ).toMap(),
    );

    // 2. Update Customer totals
    final newRemainingDue =
        (customer.remainingDue - amount).clamp(0.0, double.infinity);
    final finalRemainingDue = newRemainingDue <= 0.001 ? 0.0 : newRemainingDue;
    batch.update(customerRef, {
      FirestoreConstants.totalPaid: FieldValue.increment(amount),
      FirestoreConstants.remainingDue: finalRemainingDue,
      FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
    });

    // 3. Query sales belonging to this user and customer
    final salesQuery = await _firestore
        .collection(FirestoreConstants.sales)
        .where(FirestoreConstants.userId, isEqualTo: userId)
        .get();

    final customerSales = salesQuery.docs
        .map((doc) => Sale.fromFirestore(doc))
        .where((s) =>
            s.customerId == customerId ||
            (customer.contactNumber.isNotEmpty &&
                s.contactNumber == customer.contactNumber))
        .toList();

    // Prioritize specific saleId if provided, otherwise FIFO by date
    customerSales.sort((a, b) {
      if (saleId.isNotEmpty) {
        if (a.id == saleId) return -1;
        if (b.id == saleId) return 1;
      }
      return a.date.compareTo(b.date);
    });

    final isCustomerDueFullyCleared = finalRemainingDue <= 0.001;
    double remainingToAllocate = amount;

    for (final s in customerSales) {
      final docRef = _firestore.collection(FirestoreConstants.sales).doc(s.id);

      if (isCustomerDueFullyCleared) {
        // Customer has cleared all due: mark every sale as paid!
        batch.update(docRef, {
          FirestoreConstants.dueAmount: 0.0,
          FirestoreConstants.paidAmount: s.totalAmount,
          FirestoreConstants.paymentStatus: FirestoreConstants.paid,
          FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
        });
        continue;
      }

      // Partial payment: allocate amount to sales with due
      final currentDue = s.dueAmount > 0
          ? s.dueAmount
          : (s.totalAmount - s.paidAmount).clamp(0.0, double.infinity);

      if (remainingToAllocate > 0.001 && currentDue > 0.001) {
        final allocate = remainingToAllocate >= currentDue
            ? currentDue
            : remainingToAllocate;
        final newPaid = s.paidAmount + allocate;
        final rawDue = (currentDue - allocate).clamp(0.0, double.infinity);
        final newDue = rawDue <= 0.001 ? 0.0 : rawDue;
        final newStatus = (newDue <= 0.001 || newPaid >= s.totalAmount - 0.001)
            ? FirestoreConstants.paid
            : FirestoreConstants.partialPaid;

        batch.update(docRef, {
          FirestoreConstants.paidAmount: newPaid,
          FirestoreConstants.dueAmount: newDue,
          FirestoreConstants.paymentStatus: newStatus,
          FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
        });

        remainingToAllocate -= allocate;
      } else if (currentDue <= 0.001 &&
          s.paymentStatus != FirestoreConstants.paid) {
        // Due was already 0, ensure status reflects 'paid'
        batch.update(docRef, {
          FirestoreConstants.dueAmount: 0.0,
          FirestoreConstants.paymentStatus: FirestoreConstants.paid,
          FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  /// Sync any existing sales whose customer has cleared all due or where dueAmount is 0
  Future<void> syncClearedSalesStatus(String userId) async {
    try {
      final customersQuery = await _firestore
          .collection(FirestoreConstants.customers)
          .where(FirestoreConstants.userId, isEqualTo: userId)
          .get();

      final clearedCustomerIds = <String>{};
      final clearedCustomerPhones = <String>{};

      for (final doc in customersQuery.docs) {
        final c = Customer.fromFirestore(doc);
        if (c.remainingDue <= 0.001) {
          clearedCustomerIds.add(c.id);
          if (c.contactNumber.isNotEmpty) {
            clearedCustomerPhones.add(c.contactNumber);
          }
        }
      }

      final salesQuery = await _firestore
          .collection(FirestoreConstants.sales)
          .where(FirestoreConstants.userId, isEqualTo: userId)
          .get();

      WriteBatch? batch;
      int count = 0;

      for (final doc in salesQuery.docs) {
        final s = Sale.fromFirestore(doc);
        final isCustomerCleared = clearedCustomerIds.contains(s.customerId) ||
            (s.contactNumber.isNotEmpty &&
                clearedCustomerPhones.contains(s.contactNumber));

        final shouldBePaid = isCustomerCleared ||
            s.dueAmount <= 0.001 ||
            (s.totalAmount > 0 && s.paidAmount >= s.totalAmount - 0.001);

        if (shouldBePaid &&
            (s.paymentStatus != FirestoreConstants.paid ||
                (isCustomerCleared && s.dueAmount > 0.001))) {
          batch ??= _firestore.batch();
          batch.update(doc.reference, {
            FirestoreConstants.paymentStatus: FirestoreConstants.paid,
            FirestoreConstants.dueAmount: 0.0,
            if (isCustomerCleared) FirestoreConstants.paidAmount: s.totalAmount,
            FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
          });
          count++;
          if (count >= 400) {
            await batch.commit();
            batch = _firestore.batch();
            count = 0;
          }
        }
      }

      if (batch != null && count > 0) {
        await batch.commit();
      }
    } catch (_) {
      // Non-blocking background sync
    }
  }
}
