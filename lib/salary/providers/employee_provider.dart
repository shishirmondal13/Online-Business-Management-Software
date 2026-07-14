import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/constants/firestore_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/employee.dart';

final employeeListProvider = StreamProvider<List<Employee>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(FirestoreConstants.employees)
      .orderBy('name')
      .snapshots()
      .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => Employee.fromFirestore(doc))
            .toList();
        return list;
      });
});

final activeEmployeeListProvider = StreamProvider<List<Employee>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(FirestoreConstants.employees)
      .where('isActive', isEqualTo: true)
      .orderBy('name')
      .snapshots()
      .map((snapshot) {
        final employees = snapshot.docs
            .map((doc) => Employee.fromFirestore(doc))
            .toList();
        return employees;
      });
});

final employeeServiceProvider = Provider<EmployeeService>((ref) {
  return EmployeeService();
});

class EmployeeService {
  final _firestore = FirebaseFirestore.instance;

  Future<void> addEmployee(Employee employee) async {
    await _firestore
        .collection(FirestoreConstants.employees)
        .doc(employee.id)
        .set(employee.toMap());
  }

  Future<void> updateEmployee(Employee employee) async {
    await _firestore
        .collection(FirestoreConstants.employees)
        .doc(employee.id)
        .update(employee.toMap());
  }

  Future<void> deleteEmployee(String id) async {
    await _firestore.collection(FirestoreConstants.employees).doc(id).delete();
  }
}
