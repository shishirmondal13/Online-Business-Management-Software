import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../shared/constants/firestore_constants.dart';
import '../../auth/providers/auth_provider.dart';

import '../models/transport_cost.dart';

/// Transport cost list provider (filtered by userId)
final transportCostListProvider = StreamProvider<List<TransportCost>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(FirestoreConstants.transportCosts)
      .snapshots()
      .map((snap) {
        final list = snap.docs
            .map((doc) => TransportCost.fromFirestore(doc))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
});

/// Transport cost for specific product (filtered by productCode)
final transportCostForProductProvider =
    FutureProvider.family<TransportCost?, String>((ref, productCode) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) return null;

      final snap = await FirebaseFirestore.instance
          .collection(FirestoreConstants.transportCosts)
          .where(FirestoreConstants.productCode, isEqualTo: productCode)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;
      return TransportCost.fromFirestore(snap.docs.first);
    });

/// Transport cost service
final transportCostServiceProvider = Provider<TransportCostService>(
  (ref) => TransportCostService(),
);

class TransportCostService {
  final _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Future<String> addTransportCost(TransportCost cost) async {
    final id = _uuid.v4();
    final newCost = cost.copyWith(id: id);
    await _firestore
        .collection(FirestoreConstants.transportCosts)
        .doc(id)
        .set(newCost.toMap());
    return id;
  }

  Future<void> updateTransportCost(TransportCost cost) async {
    await _firestore
        .collection(FirestoreConstants.transportCosts)
        .doc(cost.id)
        .update(cost.copyWith(updatedAt: DateTime.now()).toMap());
  }

  Future<void> deleteTransportCost(String id) async {
    await _firestore
        .collection(FirestoreConstants.transportCosts)
        .doc(id)
        .delete();
  }
}
