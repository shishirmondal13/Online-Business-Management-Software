import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base Firestore service provider
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Generic Firestore service for CRUD operations
class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService(this._firestore);

  /// Get collection reference
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  /// Get document reference
  DocumentReference<Map<String, dynamic>> document(String path) {
    return _firestore.doc(path);
  }

  /// Create or update a document
  Future<void> setDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    await _firestore
        .collection(collection)
        .doc(documentId)
        .set(data, SetOptions(merge: merge));
  }

  /// Get a single document
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument({
    required String collection,
    required String documentId,
  }) async {
    return await _firestore.collection(collection).doc(documentId).get();
  }

  /// Delete a document
  Future<void> deleteDocument({
    required String collection,
    required String documentId,
  }) async {
    await _firestore.collection(collection).doc(documentId).delete();
  }

  /// Query documents
  Future<QuerySnapshot<Map<String, dynamic>>> queryDocuments({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(collection);

    if (filters != null) {
      for (final filter in filters) {
        query = _applyFilter(query, filter);
      }
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return await query.get();
  }

  /// Stream documents
  Stream<QuerySnapshot<Map<String, dynamic>>> streamDocuments({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(collection);

    if (filters != null) {
      for (final filter in filters) {
        query = _applyFilter(query, filter);
      }
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  /// Stream a single document
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDocument({
    required String collection,
    required String documentId,
  }) {
    return _firestore.collection(collection).doc(documentId).snapshots();
  }

  /// Apply filter to query
  Query<Map<String, dynamic>> _applyFilter(
    Query<Map<String, dynamic>> query,
    QueryFilter filter,
  ) {
    switch (filter.operator) {
      case FilterOperator.equals:
        return query.where(filter.field, isEqualTo: filter.value);
      case FilterOperator.notEquals:
        return query.where(filter.field, isNotEqualTo: filter.value);
      case FilterOperator.lessThan:
        return query.where(filter.field, isLessThan: filter.value);
      case FilterOperator.lessThanOrEquals:
        return query.where(filter.field, isLessThanOrEqualTo: filter.value);
      case FilterOperator.greaterThan:
        return query.where(filter.field, isGreaterThan: filter.value);
      case FilterOperator.greaterThanOrEquals:
        return query.where(filter.field, isGreaterThanOrEqualTo: filter.value);
      case FilterOperator.arrayContains:
        return query.where(filter.field, arrayContains: filter.value);
      case FilterOperator.whereIn:
        return query.where(filter.field, whereIn: filter.value);
    }
  }

  /// Batch write
  WriteBatch batch() {
    return _firestore.batch();
  }

  /// Run transaction
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) transactionHandler,
  ) {
    return _firestore.runTransaction(transactionHandler);
  }

  /// Check if document exists
  Future<bool> documentExists({
    required String collection,
    required String documentId,
  }) async {
    final doc = await _firestore.collection(collection).doc(documentId).get();
    return doc.exists;
  }

  /// Check uniqueness of a field value
  Future<bool> isFieldValueUnique({
    required String collection,
    required String field,
    required dynamic value,
    String? excludeDocumentId,
  }) async {
    var query = _firestore
        .collection(collection)
        .where(field, isEqualTo: value);
    final snapshot = await query.get();

    if (snapshot.docs.isEmpty) return true;

    if (excludeDocumentId != null && snapshot.docs.length == 1) {
      return snapshot.docs.first.id == excludeDocumentId;
    }

    return false;
  }

  /// Enable offline persistence (should be called during app init)
  Future<void> enableOfflinePersistence() async {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
}

/// Query filter model
class QueryFilter {
  final String field;
  final FilterOperator operator;
  final dynamic value;

  const QueryFilter({
    required this.field,
    required this.operator,
    required this.value,
  });

  factory QueryFilter.equals(String field, dynamic value) {
    return QueryFilter(
      field: field,
      operator: FilterOperator.equals,
      value: value,
    );
  }

  factory QueryFilter.greaterThan(String field, dynamic value) {
    return QueryFilter(
      field: field,
      operator: FilterOperator.greaterThan,
      value: value,
    );
  }

  factory QueryFilter.lessThan(String field, dynamic value) {
    return QueryFilter(
      field: field,
      operator: FilterOperator.lessThan,
      value: value,
    );
  }
}

enum FilterOperator {
  equals,
  notEquals,
  lessThan,
  lessThanOrEquals,
  greaterThan,
  greaterThanOrEquals,
  arrayContains,
  whereIn,
}

/// Firestore service provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreService(firestore);
});
