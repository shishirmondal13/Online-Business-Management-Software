import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/constants/firestore_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/expense.dart';

class ExpenseService {
  final FirebaseFirestore _firestore;

  ExpenseService(this._firestore);

  Future<void> addExpense(AppExpense expense) async {
    final docRef = _firestore.collection(FirestoreConstants.expenses).doc();
    final expenseWithId = AppExpense(
      id: docRef.id,
      userId: expense.userId,
      expenseType: expense.expenseType,
      amount: expense.amount,
      date: expense.date,
      notes: expense.notes,
      createdAt: expense.createdAt,
      updatedAt: expense.updatedAt,
    );
    await docRef.set(expenseWithId.toMap());
  }

  Future<void> updateExpense(
    String id,
    double oldAmount,
    double newAmount,
    String newNotes,
    String userId,
  ) async {
    await _firestore.collection(FirestoreConstants.expenses).doc(id).update({
      'amount': newAmount,
      'notes': newNotes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final expenseListProvider = StreamProvider<List<AppExpense>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(FirestoreConstants.expenses)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => AppExpense.fromFirestore(doc))
            .toList();
        return list;
      });
});

final expenseServiceProvider = Provider<ExpenseService>((ref) {
  return ExpenseService(FirebaseFirestore.instance);
});
