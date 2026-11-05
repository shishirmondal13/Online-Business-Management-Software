import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/base_model.dart';

/// Transport cost model for gadget products
class TransportCost extends BaseModel {
  final String productCode;
  final String productName;
  final double perKgPrice;
  final double productWeightGrams;
  final double perGramPrice; // Auto-calculated
  final double transportCost; // Auto-calculated

  const TransportCost({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    required this.productCode,
    required this.productName,
    required this.perKgPrice,
    required this.productWeightGrams,
    required this.perGramPrice,
    required this.transportCost,
  });

  factory TransportCost.fromMap(Map<String, dynamic> map, String id) {
    return TransportCost(
      id: id,
      userId: map['userId'] ?? '',
      productCode: map['productCode'] ?? '',
      productName: map['productName'] ?? '',
      perKgPrice: (map['perKgPrice'] ?? 0).toDouble(),
      productWeightGrams: (map['productWeightGrams'] ?? 0).toDouble(),
      perGramPrice: (map['perGramPrice'] ?? 0).toDouble(),
      transportCost: (map['transportCost'] ?? 0).toDouble(),
      createdAt: BaseModel.timestampToDate(map['createdAt']),
      updatedAt: BaseModel.timestampToDate(map['updatedAt']),
    );
  }

  factory TransportCost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TransportCost.fromMap(data, doc.id);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productCode': productCode,
      'productName': productName,
      'perKgPrice': perKgPrice,
      'productWeightGrams': productWeightGrams,
      'perGramPrice': perGramPrice,
      'transportCost': transportCost,
      'createdAt': BaseModel.dateToTimestamp(createdAt),
      'updatedAt': BaseModel.dateToTimestamp(updatedAt),
    };
  }

  TransportCost copyWith({
    String? id,
    String? userId,
    String? productCode,
    String? productName,
    double? perKgPrice,
    double? productWeightGrams,
    double? perGramPrice,
    double? transportCost,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransportCost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      perKgPrice: perKgPrice ?? this.perKgPrice,
      productWeightGrams: productWeightGrams ?? this.productWeightGrams,
      perGramPrice: perGramPrice ?? this.perGramPrice,
      transportCost: transportCost ?? this.transportCost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TransportCost.create({
    required String userId,
    required String productCode,
    required String productName,
    required double perKgPrice,
    required double productWeightGrams,
  }) {
    final now = DateTime.now();
    final perGramPrice = perKgPrice / 1000;
    final transportCost = perGramPrice * productWeightGrams;

    return TransportCost(
      id: '',
      userId: userId,
      productCode: productCode,
      productName: productName,
      perKgPrice: perKgPrice,
      productWeightGrams: productWeightGrams,
      perGramPrice: perGramPrice,
      transportCost: transportCost,
      createdAt: now,
      updatedAt: now,
    );
  }
}
