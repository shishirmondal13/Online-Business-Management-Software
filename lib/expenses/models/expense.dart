import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/base_model.dart';

class AppExpense extends BaseModel {
  final String expenseType;
  final double amount;
  final DateTime date;
  final String notes;

  const AppExpense({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    required this.expenseType,
    required this.amount,
    required this.date,
    required this.notes,
  });

  factory AppExpense.fromMap(Map<String, dynamic> map, String id) {
    return AppExpense(
      id: id,
      userId: map['userId'] ?? '',
      expenseType: map['expenseType'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: BaseModel.timestampToDate(map['date']),
      notes: map['notes'] ?? '',
      createdAt: BaseModel.timestampToDate(map['createdAt']),
      updatedAt: BaseModel.timestampToDate(map['updatedAt']),
    );
  }

  factory AppExpense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppExpense.fromMap(data, doc.id);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'expenseType': expenseType,
      'amount': amount,
      'date': BaseModel.dateToTimestamp(date),
      'notes': notes,
      'createdAt': BaseModel.dateToTimestamp(createdAt),
      'updatedAt': BaseModel.dateToTimestamp(updatedAt),
    };
  }

  factory AppExpense.create({
    required String userId,
    required String expenseType,
    required double amount,
    required DateTime date,
    required String notes,
  }) {
    final now = DateTime.now();
    return AppExpense(
      id: '',
      userId: userId,
      expenseType: expenseType,
      amount: amount,
      date: date,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }
}
