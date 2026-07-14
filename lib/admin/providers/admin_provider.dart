import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/user_model.dart';
import '../../shared/constants/firestore_constants.dart';

/// Provider for list of all users
final allUsersProvider = StreamProvider<List<AppUser>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreConstants.users)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
      });
});

/// Admin service for managing users
final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(FirebaseFirestore.instance);
});

class AdminService {
  final FirebaseFirestore _firestore;

  AdminService(this._firestore);

  /// Toggle user access level
  Future<void> updateUserAccess(String userId, String accessLevel) async {
    await _firestore.collection(FirestoreConstants.users).doc(userId).update({
      'accessLevel': accessLevel,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Toggle user role
  Future<void> updateUserRole(String userId, String role) async {
    await _firestore.collection(FirestoreConstants.users).doc(userId).update({
      'role': role,
      'updatedAt': Timestamp.now(),
    });
  }
}
