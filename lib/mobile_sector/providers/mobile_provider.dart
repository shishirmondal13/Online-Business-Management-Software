import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../shared/constants/firestore_constants.dart';
import '../../auth/providers/auth_provider.dart';

import '../models/mobile_stock.dart';

/// Mobile stock list provider
final mobileStockListProvider = StreamProvider<List<MobileStock>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(FirestoreConstants.mobileStock)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => MobileStock.fromFirestore(doc))
            .toList();
        return list;
      });
});

/// Filtered mobile stock list (by status)
final filteredMobileStockProvider =
    Provider.family<AsyncValue<List<MobileStock>>, String?>((ref, status) {
      final stockList = ref.watch(mobileStockListProvider);

      return stockList.whenData((list) {
        if (status == null || status.isEmpty) return list;
        return list.where((item) => item.status == status).toList();
      });
    });

/// Search mobile stock
final searchMobileStockProvider =
    Provider.family<AsyncValue<List<MobileStock>>, String>((ref, query) {
      final stockList = ref.watch(mobileStockListProvider);

      return stockList.whenData((list) {
        if (query.isEmpty) return list;

        final lowerQuery = query.toLowerCase();
        return list.where((item) {
          return item.modelName.toLowerCase().contains(lowerQuery) ||
              item.imeiNumber.toLowerCase().contains(lowerQuery);
        }).toList();
      });
    });

/// Single mobile stock provider
final mobileStockProvider = FutureProvider.family<MobileStock?, String>((
  ref,
  id,
) async {
  final doc = await FirebaseFirestore.instance
      .collection(FirestoreConstants.mobileStock)
      .doc(id)
      .get();

  if (!doc.exists) return null;
  return MobileStock.fromFirestore(doc);
});

/// Mobile stock service provider
final mobileStockServiceProvider = Provider<MobileStockService>((ref) {
  return MobileStockService();
});

/// Mobile stock CRUD service
class MobileStockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Add new mobile stock
  Future<String> addMobileStock(MobileStock stock) async {
    // Check IMEI uniqueness for this user
    final existing = await _firestore
        .collection(FirestoreConstants.mobileStock)
        .where(FirestoreConstants.imeiNumber, isEqualTo: stock.imeiNumber)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('IMEI number already exists');
    }

    final id = _uuid.v4();
    final newStock = stock.copyWith(id: id);

    await _firestore
        .collection(FirestoreConstants.mobileStock)
        .doc(id)
        .set(newStock.toMap());
    return id;
  }

  /// Update mobile stock
  Future<void> updateMobileStock(MobileStock stock) async {
    // Check IMEI uniqueness (excluding current document) for this user
    final existing = await _firestore
        .collection(FirestoreConstants.mobileStock)
        .where(FirestoreConstants.imeiNumber, isEqualTo: stock.imeiNumber)
        .limit(2)
        .get();

    for (final doc in existing.docs) {
      if (doc.id != stock.id) {
        throw Exception('IMEI number already exists');
      }
    }

    final updatedStock = stock.copyWith(updatedAt: DateTime.now());
    await _firestore
        .collection(FirestoreConstants.mobileStock)
        .doc(stock.id)
        .update(updatedStock.toMap());
  }

  /// Delete mobile stock
  Future<void> deleteMobileStock(String id) async {
    await _firestore
        .collection(FirestoreConstants.mobileStock)
        .doc(id)
        .delete();
  }



  /// Mark as sold
  Future<void> markAsSold(String id, double? finalSellingPrice) async {
    final doc = await _firestore
        .collection(FirestoreConstants.mobileStock)
        .doc(id)
        .get();

    if (!doc.exists) throw Exception('Mobile stock not found');

    final stock = MobileStock.fromFirestore(doc);
    final sellingPrice = finalSellingPrice ?? stock.sellingPrice;
    final profit = sellingPrice - stock.netPurchasePrice;

    await _firestore.collection(FirestoreConstants.mobileStock).doc(id).update({
      'status': 'sold',
      'soldDate': Timestamp.now(),
      'sellingPrice': sellingPrice,
      'profit': profit,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Mark as unsold
  Future<void> markAsUnsold(String id) async {
    await _firestore.collection(FirestoreConstants.mobileStock).doc(id).update({
      'status': 'unsold',
      'soldDate': null,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Check if IMEI exists for this user
  Future<bool> imeiExists(
    String imei, {
    required String userId,
    String? excludeId,
  }) async {
    final query = await _firestore
        .collection(FirestoreConstants.mobileStock)
        .where(FirestoreConstants.imeiNumber, isEqualTo: imei)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return false;
    if (excludeId != null && query.docs.first.id == excludeId) return false;
    return true;
  }
}

/// Mobile stock form state
class MobileStockFormState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const MobileStockFormState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  MobileStockFormState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return MobileStockFormState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Mobile stock form notifier
final mobileStockFormProvider =
    StateNotifierProvider<MobileStockFormNotifier, MobileStockFormState>((ref) {
      return MobileStockFormNotifier(ref.watch(mobileStockServiceProvider));
    });

class MobileStockFormNotifier extends StateNotifier<MobileStockFormState> {
  final MobileStockService _service;

  MobileStockFormNotifier(this._service) : super(const MobileStockFormState());

  Future<bool> save(MobileStock stock, {bool isEditing = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (isEditing) {
        await _service.updateMobileStock(stock);
      } else {
        await _service.addMobileStock(stock);
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
      await _service.deleteMobileStock(id);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void reset() {
    state = const MobileStockFormState();
  }
}
