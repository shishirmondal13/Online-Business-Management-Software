import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../shared/constants/firestore_constants.dart';
import '../../auth/providers/auth_provider.dart';

import '../models/gadget_stock.dart';

/// Gadget stock list provider
final gadgetStockListProvider = StreamProvider<List<GadgetStock>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(FirestoreConstants.gadgetStock)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => GadgetStock.fromFirestore(doc))
            .toList();
        return list;
      });
});

/// Search gadget stock
final searchGadgetStockProvider =
    Provider.family<AsyncValue<List<GadgetStock>>, String>((ref, query) {
      final stockList = ref.watch(gadgetStockListProvider);

      return stockList.whenData((list) {
        if (query.isEmpty) return list;

        final lowerQuery = query.toLowerCase();
        return list.where((item) {
          return item.productName.toLowerCase().contains(lowerQuery) ||
              item.productCode.toLowerCase().contains(lowerQuery);
        }).toList();
      });
    });

/// Filter by stock status
final filteredGadgetStockProvider =
    Provider.family<AsyncValue<List<GadgetStock>>, String?>((ref, status) {
      final stockList = ref.watch(gadgetStockListProvider);

      return stockList.whenData((list) {
        if (status == null || status.isEmpty) return list;
        return list.where((item) => item.stockStatus == status).toList();
      });
    });

/// Single gadget stock provider
final gadgetStockProvider = FutureProvider.family<GadgetStock?, String>((
  ref,
  id,
) async {
  final doc = await FirebaseFirestore.instance
      .collection(FirestoreConstants.gadgetStock)
      .doc(id)
      .get();

  if (!doc.exists) return null;
  return GadgetStock.fromFirestore(doc);
});

/// Gadget stock service provider
final gadgetStockServiceProvider = Provider<GadgetStockService>((ref) {
  return GadgetStockService();
});

/// Gadget stock CRUD service
class GadgetStockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Future<String> addGadgetStock(GadgetStock stock) async {
    // 1. Verify uniqueness for the product code
    final existing = await _firestore
        .collection(FirestoreConstants.gadgetStock)
        .where(FirestoreConstants.productCode, isEqualTo: stock.productCode)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception(
        'Product code ${stock.productCode} already exists.',
      );
    }

    final id = _uuid.v4();
    final newStock = stock.copyWith(id: id);

    await _firestore
        .collection(FirestoreConstants.gadgetStock)
        .doc(id)
        .set(newStock.toMap());

    return id;
  }

  /// Update gadget stock
  Future<void> updateGadgetStock(GadgetStock stock) async {
    // Check product code uniqueness (excluding current document) for this user
    final existing = await _firestore
        .collection(FirestoreConstants.gadgetStock)
        .where(FirestoreConstants.productCode, isEqualTo: stock.productCode)
        .limit(2)
        .get();

    for (final doc in existing.docs) {
      if (doc.id != stock.id) {
        throw Exception('Product code already exists');
      }
    }

    final updatedStock = stock.copyWith(updatedAt: DateTime.now());
    await _firestore
        .collection(FirestoreConstants.gadgetStock)
        .doc(stock.id)
        .update(updatedStock.toMap());
  }

  /// Delete gadget stock
  Future<void> deleteGadgetStock(String id) async {
    await _firestore
        .collection(FirestoreConstants.gadgetStock)
        .doc(id)
        .delete();
  }



  /// Update quantity
  Future<void> updateQuantity(String id, int newQuantity) async {
    String stockStatus = 'in_stock';
    if (newQuantity == 0) {
      stockStatus = 'out_of_stock';
    } else if (newQuantity <= 5) {
      stockStatus = 'low_stock';
    }

    await _firestore.collection(FirestoreConstants.gadgetStock).doc(id).update({
      'quantity': newQuantity,
      'stockStatus': stockStatus,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Check if product code exists for this user
  Future<bool> productCodeExists(
    String code, {
    required String userId,
    String? excludeId,
  }) async {
    final query = await _firestore
        .collection(FirestoreConstants.gadgetStock)
        .where(FirestoreConstants.productCode, isEqualTo: code)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return false;
    if (excludeId != null && query.docs.first.id == excludeId) return false;
    return true;
  }
}

/// Gadget stock form state
class GadgetStockFormState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const GadgetStockFormState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  GadgetStockFormState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return GadgetStockFormState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Gadget stock form notifier
final gadgetStockFormProvider =
    StateNotifierProvider<GadgetStockFormNotifier, GadgetStockFormState>((ref) {
      return GadgetStockFormNotifier(ref.watch(gadgetStockServiceProvider));
    });

class GadgetStockFormNotifier extends StateNotifier<GadgetStockFormState> {
  final GadgetStockService _service;

  GadgetStockFormNotifier(this._service) : super(const GadgetStockFormState());

  Future<bool> save(GadgetStock stock, {bool isEditing = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (isEditing) {
        await _service.updateGadgetStock(stock);
      } else {
        await _service.addGadgetStock(stock);
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> delete(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.deleteGadgetStock(id);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void reset() {
    state = const GadgetStockFormState();
  }
}
