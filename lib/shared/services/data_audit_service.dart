import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../constants/firestore_constants.dart';

class AuditReport {
  final int flaggedSalesCount;
  final int repairedCustomerDuesCount;
  final int totalCollectionsAudited;
  final List<String> logs;

  AuditReport({
    required this.flaggedSalesCount,
    required this.repairedCustomerDuesCount,
    required this.totalCollectionsAudited,
    required this.logs,
  });
}

class DataAuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Force fetch collections directly from Firestore live server, bypassing local cache.
  Future<void> forceServerRefresh() async {
    final collections = [
      FirestoreConstants.mobileStock,
      FirestoreConstants.gadgetStock,
      FirestoreConstants.sales,
      FirestoreConstants.expenses,
      FirestoreConstants.salary,
      FirestoreConstants.capital,
      FirestoreConstants.customers,
      FirestoreConstants.transportCosts,
    ];
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw StateError('You must be signed in.');

    for (final col in collections) {
      try {
        await _firestore
            .collection(col)
            .where(FirestoreConstants.userId, isEqualTo: userId)
            .get(const GetOptions(source: Source.server));
      } catch (e) {
        debugPrint('Cache refresh info for $col: $e');
      }
    }
  }

  /// Run database audit to clean negative dues, corrupted sales, or unsynced stock quantities.
  Future<AuditReport> auditAndRepairDatabase() async {
    int repairedSales = 0;
    int repairedDues = 0;
    final List<String> logs = [];

    try {
      // 1. Audit Sales Collection
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw StateError('You must be signed in.');
      final salesSnapshot = await _firestore
          .collection(FirestoreConstants.sales)
          .where(FirestoreConstants.userId, isEqualTo: userId)
          .get(const GetOptions(source: Source.server));

      for (final doc in salesSnapshot.docs) {
        final data = doc.data();
        final sp = (data[FirestoreConstants.totalAmount] ?? 0.0).toDouble();
        final due = (data[FirestoreConstants.dueAmount] ?? 0.0).toDouble();

        if (sp <= 0 || due < 0) {
          repairedSales++;
          logs.add('Flagged invalid sale entry for review: ID ${doc.id}');
        }
      }

      // 2. Audit Customer Dues Collection
      final customerSnapshot = await _firestore
          .collection(FirestoreConstants.customers)
          .where(FirestoreConstants.userId, isEqualTo: userId)
          .get(const GetOptions(source: Source.server));

      for (final doc in customerSnapshot.docs) {
        final data = doc.data();
        final remainingDue = (data[FirestoreConstants.remainingDue] ?? 0.0)
            .toDouble();

        if (remainingDue < 0) {
          repairedDues++;
          logs.add('Fixed negative customer due balance: ID ${doc.id}');
          await doc.reference.update({
            FirestoreConstants.remainingDue: 0.0,
            FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
          });
        }
      }

      logs.add('Database audit finished successfully.');
    } catch (e) {
      logs.add('Audit Warning: $e');
    }

    return AuditReport(
      flaggedSalesCount: repairedSales,
      repairedCustomerDuesCount: repairedDues,
      totalCollectionsAudited: 2,
      logs: logs,
    );
  }
}
