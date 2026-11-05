import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/base_model.dart';

/// Damage event model tracking damaged mobile and gadget stock
class DamageEvent extends BaseModel {
  final String productType; // 'mobile' or 'gadget'
  final String productId;
  final String productName;
  final String identifier; // IMEI for mobile, Product Code for gadget
  final int quantity;
  final double unitCost;
  final double damageValue; // Total financial loss = unitCost * quantity
  final String reason;
  final DateTime date;

  const DamageEvent({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    required this.productType,
    required this.productId,
    required this.productName,
    required this.identifier,
    required this.quantity,
    required this.unitCost,
    required this.damageValue,
    required this.reason,
    required this.date,
  });

  factory DamageEvent.fromMap(Map<String, dynamic> map, String id) {
    return DamageEvent(
      id: id,
      userId: map['userId'] ?? '',
      productType: map['productType'] ?? 'mobile',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      identifier: map['identifier'] ?? map['imeiNumber'] ?? map['productCode'] ?? '',
      quantity: (map['quantity'] ?? 1) is int
          ? map['quantity'] as int
          : (map['quantity'] as num?)?.toInt() ?? 1,
      unitCost: (map['unitCost'] ?? 0).toDouble(),
      damageValue: (map['damageValue'] ?? 0).toDouble(),
      reason: map['reason'] ?? '',
      date: BaseModel.timestampToDate(map['date']),
      createdAt: BaseModel.timestampToDate(map['createdAt']),
      updatedAt: BaseModel.timestampToDate(map['updatedAt']),
    );
  }

  factory DamageEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DamageEvent.fromMap(data, doc.id);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productType': productType,
      'productId': productId,
      'productName': productName,
      'identifier': identifier,
      'quantity': quantity,
      'unitCost': unitCost,
      'damageValue': damageValue,
      'reason': reason,
      'date': BaseModel.dateToTimestamp(date),
      'createdAt': BaseModel.dateToTimestamp(createdAt),
      'updatedAt': BaseModel.dateToTimestamp(updatedAt),
    };
  }

  DamageEvent copyWith({
    String? id,
    String? userId,
    String? productType,
    String? productId,
    String? productName,
    String? identifier,
    int? quantity,
    double? unitCost,
    double? damageValue,
    String? reason,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DamageEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productType: productType ?? this.productType,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      identifier: identifier ?? this.identifier,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      damageValue: damageValue ?? this.damageValue,
      reason: reason ?? this.reason,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isMobile => productType.toLowerCase().trim() == 'mobile';
  bool get isGadget => productType.toLowerCase().trim() == 'gadget';
}
