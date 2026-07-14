import 'package:cloud_firestore/cloud_firestore.dart';

/// Base model class with common fields
abstract class BaseModel {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BaseModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap();

  /// Convert DateTime to Firestore Timestamp
  static Timestamp dateToTimestamp(DateTime date) {
    return Timestamp.fromDate(date);
  }

  /// Convert Firestore Timestamp to DateTime
  static DateTime timestampToDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    if (timestamp is DateTime) {
      return timestamp;
    }
    return DateTime.now();
  }

  /// Convert map to DateTime safely
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Mixin for synced models
mixin SyncableMixin {
  bool get isSynced;
  DateTime? get lastSyncedAt;
}
