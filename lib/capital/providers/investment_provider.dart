import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/providers/auth_provider.dart';

import '../models/investment_transaction.dart';

final investmentHistoryProvider = StreamProvider<List<InvestmentTransaction>>((
  ref,
) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('investment_history')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => InvestmentTransaction.fromFirestore(doc))
            .toList();
        return list;
      });
});

final investmentServiceProvider = Provider<InvestmentService>((ref) {
  return InvestmentService();
});

class InvestmentService {
  final _firestore = FirebaseFirestore.instance;

  Future<void> addTransaction({
    required String userId,
    required double amount,
    required String type,
    required String note,
    required String investorName,
  }) async {
    final now = DateTime.now();
    final transactionRef = _firestore.collection('investment_history').doc();
    final transaction = InvestmentTransaction(
      id: transactionRef.id,
      userId: userId,
      createdAt: now,
      updatedAt: now,
      amount: amount,
      type: type,
      note: note,
      date: now,
      investorName: investorName,
    );
    await transactionRef.set(transaction.toMap());
  }

  Future<void> updateTransaction({
    required InvestmentTransaction oldTransaction,
    required double newAmount,
    required String newType,
    required String newNote,
    required String newInvestorName,
  }) async {
    final now = DateTime.now();
    final transactionRef = _firestore
        .collection('investment_history')
        .doc(oldTransaction.id);

    final updatedTransaction = oldTransaction.copyWith(
      amount: newAmount,
      type: newType,
      note: newNote,
      investorName: newInvestorName,
      updatedAt: now,
    );

    await transactionRef.update(updatedTransaction.toMap());
  }
}
