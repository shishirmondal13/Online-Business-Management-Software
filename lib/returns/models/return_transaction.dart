import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/base_model.dart';

class ReturnTransaction extends BaseModel {
  final DateTime date;
  final String saleId;
  final String productType;
  final String productId;
  final String productName;
  final int quantity;
  final double unitSalePrice;
  final double refundAmount;
  final double dueReduction;
  final double cashRefund;
  final String condition; // resalable or damaged
  final String reason;
  final String customerId;
  final String customerName;
  final String refundMethod;
  final String notes;

  const ReturnTransaction({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    required this.date,
    required this.saleId,
    required this.productType,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitSalePrice,
    required this.refundAmount,
    required this.dueReduction,
    required this.cashRefund,
    required this.condition,
    required this.reason,
    required this.customerId,
    required this.customerName,
    required this.refundMethod,
    required this.notes,
  });

  factory ReturnTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ReturnTransaction(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: BaseModel.timestampToDate(data['date']),
      saleId: data['saleId'] ?? '',
      productType: data['productType'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      quantity: (data['quantity'] ?? 0).toInt(),
      unitSalePrice: (data['unitSalePrice'] ?? 0).toDouble(),
      refundAmount: (data['refundAmount'] ?? 0).toDouble(),
      dueReduction: (data['dueReduction'] ?? 0).toDouble(),
      cashRefund: (data['cashRefund'] ?? 0).toDouble(),
      condition: data['condition'] ?? 'resalable',
      reason: data['reason'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      refundMethod: data['refundMethod'] ?? 'cash',
      notes: data['notes'] ?? '',
      createdAt: BaseModel.timestampToDate(data['createdAt']),
      updatedAt: BaseModel.timestampToDate(data['updatedAt']),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'date': BaseModel.dateToTimestamp(date),
    'saleId': saleId,
    'productType': productType,
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'unitSalePrice': unitSalePrice,
    'refundAmount': refundAmount,
    'dueReduction': dueReduction,
    'cashRefund': cashRefund,
    'condition': condition,
    'reason': reason,
    'customerId': customerId,
    'customerName': customerName,
    'refundMethod': refundMethod,
    'notes': notes,
    'createdAt': BaseModel.dateToTimestamp(createdAt),
    'updatedAt': BaseModel.dateToTimestamp(updatedAt),
  };
}
