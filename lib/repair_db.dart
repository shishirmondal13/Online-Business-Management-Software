import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'shared/constants/firestore_constants.dart';

/// One-off database repair utility.
/// Run: `flutter run -t lib/repair_db.dart`
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final fs = FirebaseFirestore.instance;

  final sales = await fs.collection(FirestoreConstants.sales).get();
  int badSalesCount = 0;

  for (var doc in sales.docs) {
    final data = doc.data();
    final sp = (data['sellingPrice'] ?? 0.0).toDouble();
    final due = (data['dueAmount'] ?? 0.0).toDouble();

    if (sp <= 0 || due < 0) {
      badSalesCount++;
      debugPrint('FIXING CORRUPTED SALE: ${doc.id}');

      final productId = data['productId'] ?? '';
      final productType = data['productType'] ?? '';

      await doc.reference.delete();

      if (productId.isNotEmpty) {
        if (productType == FirestoreConstants.mobile) {
          await fs
              .collection(FirestoreConstants.mobileStock)
              .doc(productId)
              .update({
                FirestoreConstants.status: FirestoreConstants.unsold,
                FirestoreConstants.soldDate: null,
                FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
              })
              .catchError((e) => debugPrint('Could not revert mobile: $e'));
        } else if (productType == FirestoreConstants.gadget) {
          await fs
              .collection(FirestoreConstants.gadgetStock)
              .doc(productId)
              .update({
                FirestoreConstants.quantity: FieldValue.increment(
                  data['quantity'] ?? 1,
                ),
                FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
              })
              .catchError((e) => debugPrint('Could not revert gadget: $e'));
        }
      }
    }
  }

  final customers = await fs.collection(FirestoreConstants.customers).get();
  for (var doc in customers.docs) {
    final remDue = (doc.data()['remainingDue'] ?? 0.0).toDouble();
    if (remDue < 0) {
      await doc.reference.update({
        FirestoreConstants.remainingDue: 0.0,
        FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
      });
      debugPrint('Repaired negative customer due for ${doc.id}');
    }
  }

  if (badSalesCount == 0) {
    debugPrint('No corrupted sales found. Database is clean!');
  } else {
    debugPrint(
      'Removed $badSalesCount corrupted sales and rolled back inventory.',
    );
  }
}
