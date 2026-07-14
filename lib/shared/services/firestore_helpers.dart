import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_constants.dart';
import '../models/base_model.dart';

/// Shared Firestore utilities for capital lookups and safe date parsing.
class FirestoreHelpers {
  FirestoreHelpers._();

  /// Returns the most recently created capital document for [userId], or null.
  static Future<DocumentReference<Map<String, dynamic>>?> latestCapitalRef(
    FirebaseFirestore firestore,
    String userId,
  ) async {
    final query = await firestore
        .collection(FirestoreConstants.capital)
        .get();

    if (query.docs.isEmpty) return null;

    final docs = query.docs.toList();
    docs.sort((a, b) {
      final aTime = parseTimestamp(a.data()['createdAt']) ?? DateTime(2000);
      final bTime = parseTimestamp(b.data()['createdAt']) ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });
    return docs.first.reference;
  }

  /// Applies paid-amount changes to available and recovered capital in [batch].
  static void incrementCapitalPayment(
    WriteBatch batch,
    DocumentReference<Map<String, dynamic>> capitalRef,
    double amount,
  ) {
    if (amount == 0) return;
    batch.update(capitalRef, {
      FirestoreConstants.availableCapital: FieldValue.increment(amount),
      FirestoreConstants.capitalRecovered: FieldValue.increment(amount),
      FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
    });
  }

  /// Parses a Firestore date field without throwing.
  static DateTime? parseTimestamp(dynamic value) {
    return BaseModel.parseDateTime(value);
  }

  /// Gadget stock status label from quantity.
  static String gadgetStockStatusFromQuantity(int quantity) {
    if (quantity == 0) return FirestoreConstants.outOfStock;
    if (quantity <= 5) return FirestoreConstants.lowStock;
    return FirestoreConstants.inStock;
  }
}
