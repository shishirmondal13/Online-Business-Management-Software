import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/constants/firestore_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/salary_payment.dart';

final salaryListProvider = StreamProvider<List<SalaryPayment>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(FirestoreConstants.salary)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => SalaryPayment.fromFirestore(doc))
            .toList();
        return list;
      });
});

final salaryServiceProvider = Provider<SalaryService>((ref) {
  return SalaryService();
});

class SalaryService {
  final _firestore = FirebaseFirestore.instance;

  Future<void> addSalaryPayment(SalaryPayment payment) async {
    await _firestore
        .collection(FirestoreConstants.salary)
        .doc(payment.id)
        .set(payment.toMap());
  }
}
