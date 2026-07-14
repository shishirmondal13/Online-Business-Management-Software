import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/base_model.dart';

class InvestmentTransaction extends BaseModel {
  final double amount;
  final String type; // 'add' or 'remove'
  final String note;
  final DateTime date;
  final String investorName;

  const InvestmentTransaction({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    required this.amount,
    required this.type,
    required this.note,
    required this.date,
    required this.investorName,
  });

  factory InvestmentTransaction.fromMap(Map<String, dynamic> map, String id) {
    return InvestmentTransaction(
      id: id,
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      type: map['type'] ?? 'add',
      note: map['note'] ?? '',
      date: BaseModel.timestampToDate(map['date']),
      investorName: map['investorName'] ?? '',
      createdAt: BaseModel.timestampToDate(map['createdAt']),
      updatedAt: BaseModel.timestampToDate(map['updatedAt']),
    );
  }

  factory InvestmentTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return InvestmentTransaction.fromMap(data, doc.id);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'type': type,
      'note': note,
      'date': BaseModel.dateToTimestamp(date),
      'investorName': investorName,
      'createdAt': BaseModel.dateToTimestamp(createdAt),
      'updatedAt': BaseModel.dateToTimestamp(updatedAt),
    };
  }

  InvestmentTransaction copyWith({
    String? id,
    String? userId,
    double? amount,
    String? type,
    String? note,
    DateTime? date,
    String? investorName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvestmentTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      note: note ?? this.note,
      date: date ?? this.date,
      investorName: investorName ?? this.investorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
