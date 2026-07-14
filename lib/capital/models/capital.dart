import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/base_model.dart';

class Capital extends BaseModel {
  final double initialCapital;
  final double capitalInvested;
  final double capitalRecovered;
  final double availableCapital;
  final String month;

  const Capital({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    required this.initialCapital,
    required this.capitalInvested,
    required this.capitalRecovered,
    required this.availableCapital,
    required this.month,
  });

  factory Capital.fromMap(Map<String, dynamic> map, String id) {
    return Capital(
      id: id,
      userId: map['userId'] ?? '',
      initialCapital: (map['initialCapital'] ?? 0).toDouble(),
      capitalInvested: (map['capitalInvested'] ?? 0).toDouble(),
      capitalRecovered: (map['capitalRecovered'] ?? 0).toDouble(),
      availableCapital: (map['availableCapital'] ?? 0).toDouble(),
      month: map['month'] ?? '',
      createdAt: BaseModel.timestampToDate(map['createdAt']),
      updatedAt: BaseModel.timestampToDate(map['updatedAt']),
    );
  }

  factory Capital.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Capital.fromMap(data, doc.id);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'initialCapital': initialCapital,
      'capitalInvested': capitalInvested,
      'capitalRecovered': capitalRecovered,
      'availableCapital': availableCapital,
      'month': month,
      'createdAt': BaseModel.dateToTimestamp(createdAt),
      'updatedAt': BaseModel.dateToTimestamp(updatedAt),
    };
  }

  factory Capital.create({
    required String userId,
    required double initialCapital,
    required double capitalInvested,
    required double capitalRecovered,
  }) {
    final now = DateTime.now();
    final available = initialCapital + capitalRecovered - capitalInvested;
    return Capital(
      id: '',
      userId: userId,
      initialCapital: initialCapital,
      capitalInvested: capitalInvested,
      capitalRecovered: capitalRecovered,
      availableCapital: available,
      month: '${now.year}-${now.month.toString().padLeft(2, '0')}',
      createdAt: now,
      updatedAt: now,
    );
  }
  Capital copyWith({
    String? id,
    String? userId,
    double? initialCapital,
    double? capitalInvested,
    double? capitalRecovered,
    double? availableCapital,
    String? month,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Capital(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      initialCapital: initialCapital ?? this.initialCapital,
      capitalInvested: capitalInvested ?? this.capitalInvested,
      capitalRecovered: capitalRecovered ?? this.capitalRecovered,
      availableCapital: availableCapital ?? this.availableCapital,
      month: month ?? this.month,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
