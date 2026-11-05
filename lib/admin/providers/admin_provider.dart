import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/user_model.dart';
import '../../shared/constants/firestore_constants.dart';
import '../../shared/constants/admin_accounts.dart';

/// Provider for list of all users
final allUsersProvider = StreamProvider<List<AppUser>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreConstants.users)
      .snapshots()
      .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => AppUser.fromFirestore(doc))
            .toList();
        list.sort((a, b) {
          if (a.isAdmin && !b.isAdmin) return -1;
          if (!a.isAdmin && b.isAdmin) return 1;
          return a.businessName
              .toLowerCase()
              .compareTo(b.businessName.toLowerCase());
        });
        return list;
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

  /// Bulk update access level for all regular (non-admin) users
  Future<int> updateAllUsersAccess(String accessLevel) async {
    final snapshot =
        await _firestore.collection(FirestoreConstants.users).get();
    final batch = _firestore.batch();
    int count = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final role = data['role'] ?? 'user';
      final email = data['email'] as String?;
      if (role != 'admin' && !AdminAccounts.contains(email)) {
        batch.update(doc.reference, {
          'accessLevel': accessLevel,
          'updatedAt': Timestamp.now(),
        });
        count++;
      }
    }

    if (count > 0) {
      await batch.commit();
    }
    return count;
  }
}
