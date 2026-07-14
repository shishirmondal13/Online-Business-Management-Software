import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/base_model.dart';

/// Mobile stock model (IMEI-based)
class MobileStock extends BaseModel {
  final DateTime date;
  final String modelName;
  final String imeiNumber;
  final double purchaseRate;
  final double transportCost;
  final double netPurchasePrice;
  final double sellingPrice;
  final double profit;
  final String status; // 'sold' or 'unsold'
  final DateTime? soldDate;

  const MobileStock({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    required this.date,
    required this.modelName,
    required this.imeiNumber,
    required this.purchaseRate,
    required this.transportCost,
    required this.netPurchasePrice,
    required this.sellingPrice,
    required this.profit,
    required this.status,
    this.soldDate,
  });

  factory MobileStock.fromMap(Map<String, dynamic> map, String id) {
    return MobileStock(
      id: id,
      userId: map['userId'] ?? '',
      date: BaseModel.timestampToDate(map['date']),
      modelName: map['modelName'] ?? '',
      imeiNumber: map['imeiNumber'] ?? '',
      purchaseRate: (map['purchaseRate'] ?? 0).toDouble(),
      transportCost: (map['transportCost'] ?? 0).toDouble(),
      netPurchasePrice: (map['netPurchasePrice'] ?? 0).toDouble(),
      sellingPrice: (map['sellingPrice'] ?? 0).toDouble(),
      profit: (map['profit'] ?? 0).toDouble(),
      status: map['status'] ?? 'unsold',
      soldDate: BaseModel.parseDateTime(map['soldDate']),
      createdAt: BaseModel.timestampToDate(map['createdAt']),
      updatedAt: BaseModel.timestampToDate(map['updatedAt']),
    );
  }

  factory MobileStock.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MobileStock.fromMap(data, doc.id);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': BaseModel.dateToTimestamp(date),
      'modelName': modelName,
      'imeiNumber': imeiNumber,
      'purchaseRate': purchaseRate,
      'transportCost': transportCost,
      'netPurchasePrice': netPurchasePrice,
      'sellingPrice': sellingPrice,
      'profit': profit,
      'status': status,
      'soldDate': soldDate != null
          ? BaseModel.dateToTimestamp(soldDate!)
          : null,
      'createdAt': BaseModel.dateToTimestamp(createdAt),
      'updatedAt': BaseModel.dateToTimestamp(updatedAt),
    };
  }

  MobileStock copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? modelName,
    String? imeiNumber,
    double? purchaseRate,
    double? transportCost,
    double? netPurchasePrice,
    double? sellingPrice,
    double? profit,
    String? status,
    DateTime? soldDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MobileStock(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      modelName: modelName ?? this.modelName,
      imeiNumber: imeiNumber ?? this.imeiNumber,
      purchaseRate: purchaseRate ?? this.purchaseRate,
      transportCost: transportCost ?? this.transportCost,
      netPurchasePrice: netPurchasePrice ?? this.netPurchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      profit: profit ?? this.profit,
      status: status ?? this.status,
      soldDate: soldDate ?? this.soldDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isSold => status == 'sold';
  bool get isUnsold => status == 'unsold';

  /// Create with auto-calculated fields
  factory MobileStock.create({
    required String userId,
    required DateTime date,
    required String modelName,
    required String imeiNumber,
    required double purchaseRate,
    required double transportCost,
    required double sellingPrice,
    String status = 'unsold',
  }) {
    final now = DateTime.now();
    final netPurchasePrice = purchaseRate + transportCost;
    final profit = sellingPrice - netPurchasePrice;

    return MobileStock(
      id: '',
      userId: userId,
      date: date,
      modelName: modelName,
      imeiNumber: imeiNumber,
      purchaseRate: purchaseRate,
      transportCost: transportCost,
      netPurchasePrice: netPurchasePrice,
      sellingPrice: sellingPrice,
      profit: profit,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }
}
