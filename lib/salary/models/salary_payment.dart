import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/base_model.dart';

class SalaryPayment extends BaseModel {
  final String employeeName;
  final double amount;
  final double duePaid;
  final double advance;
  final DateTime date;
  final double bonus;
  final double deductions;
  final String? notes;

  const SalaryPayment({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    required this.employeeName,
    required this.amount,
    required this.duePaid,
    required this.advance,
    required this.date,
    this.bonus = 0,
    this.deductions = 0,
    this.notes,
  });

  double get totalDeduction =>
      (amount + duePaid + advance + bonus) - deductions;

  factory SalaryPayment.fromMap(Map<String, dynamic> map, String id) {
    return SalaryPayment(
      id: id,
      userId: map['userId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      duePaid: (map['duePaid'] ?? 0).toDouble(),
      advance: (map['advance'] ?? 0).toDouble(),
      date: BaseModel.timestampToDate(map['date']),
      bonus: (map['bonus'] ?? 0).toDouble(),
      deductions: (map['deductions'] ?? 0).toDouble(),
      notes: map['notes'],
      createdAt: BaseModel.timestampToDate(map['createdAt']),
      updatedAt: BaseModel.timestampToDate(map['updatedAt']),
    );
  }

  factory SalaryPayment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SalaryPayment.fromMap(data, doc.id);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'employeeName': employeeName,
      'amount': amount,
      'duePaid': duePaid,
      'advance': advance,
      'date': BaseModel.dateToTimestamp(date),
      'bonus': bonus,
      'deductions': deductions,
      'notes': notes,
      'createdAt': BaseModel.dateToTimestamp(createdAt),
      'updatedAt': BaseModel.dateToTimestamp(updatedAt),
    };
  }
}
