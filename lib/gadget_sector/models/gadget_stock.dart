import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/base_model.dart';

/// Gadget stock model with cost breakdown
class GadgetStock extends BaseModel {
  final DateTime date;
  final String productCode;
  final String productName;
  final int quantity;
  final double purchasePrice;
  final double transportCost;
  final double packagingCost;
  final double storageCost;
  final double marketingCost;
  final double damageCost;
  final double otherCosts;
  final double productCost; // Auto-calculated
  final double profitMargin; // Percentage
  final double sellingPrice;
  final double profit; // Auto-calculated
  final String stockStatus; // 'in_stock', 'low_stock', 'out_of_stock'

  const GadgetStock({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    required this.date,
    required this.productCode,
    required this.productName,
    required this.quantity,
    required this.purchasePrice,
    required this.transportCost,
    required this.packagingCost,
    required this.storageCost,
    required this.marketingCost,
    required this.damageCost,
    required this.otherCosts,
    required this.productCost,
    required this.profitMargin,
    required this.sellingPrice,
    required this.profit,
    required this.stockStatus,
  });

  factory GadgetStock.fromMap(Map<String, dynamic> map, String id) {
    return GadgetStock(
      id: id,
      userId: map['userId'] ?? '',
      date: BaseModel.timestampToDate(map['date']),
      productCode: map['productCode'] ?? '',
      productName: map['productName'] ?? '',
      quantity: (map['quantity'] ?? 0).toInt(),
      purchasePrice: (map['purchasePrice'] ?? 0).toDouble(),
      transportCost: (map['transportCost'] ?? 0).toDouble(),
      packagingCost: (map['packagingCost'] ?? 0).toDouble(),
      storageCost: (map['storageCost'] ?? 0).toDouble(),
      marketingCost: (map['marketingCost'] ?? 0).toDouble(),
      damageCost: (map['damageCost'] ?? 0).toDouble(),
      otherCosts: (map['otherCosts'] ?? 0).toDouble(),
      productCost: (map['productCost'] ?? 0).toDouble(),
      profitMargin: (map['profitMargin'] ?? 0).toDouble(),
      sellingPrice: (map['sellingPrice'] ?? 0).toDouble(),
      profit: (map['profit'] ?? 0).toDouble(),
      stockStatus: map['stockStatus'] ?? 'in_stock',
      createdAt: BaseModel.timestampToDate(map['createdAt']),
      updatedAt: BaseModel.timestampToDate(map['updatedAt']),
    );
  }

  factory GadgetStock.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GadgetStock.fromMap(data, doc.id);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': BaseModel.dateToTimestamp(date),
      'productCode': productCode,
      'productName': productName,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'transportCost': transportCost,
      'packagingCost': packagingCost,
      'storageCost': storageCost,
      'marketingCost': marketingCost,
      'damageCost': damageCost,
      'otherCosts': otherCosts,
      'productCost': productCost,
      'profitMargin': profitMargin,
      'sellingPrice': sellingPrice,
      'profit': profit,
      'stockStatus': stockStatus,
      'createdAt': BaseModel.dateToTimestamp(createdAt),
      'updatedAt': BaseModel.dateToTimestamp(updatedAt),
    };
  }

  GadgetStock copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? productCode,
    String? productName,
    int? quantity,
    double? purchasePrice,
    double? transportCost,
    double? packagingCost,
    double? storageCost,
    double? marketingCost,
    double? damageCost,
    double? otherCosts,
    double? productCost,
    double? profitMargin,
    double? sellingPrice,
    double? profit,
    String? stockStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GadgetStock(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      transportCost: transportCost ?? this.transportCost,
      packagingCost: packagingCost ?? this.packagingCost,
      storageCost: storageCost ?? this.storageCost,
      marketingCost: marketingCost ?? this.marketingCost,
      damageCost: damageCost ?? this.damageCost,
      otherCosts: otherCosts ?? this.otherCosts,
      productCost: productCost ?? this.productCost,
      profitMargin: profitMargin ?? this.profitMargin,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      profit: profit ?? this.profit,
      stockStatus: stockStatus ?? this.stockStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate product cost from all cost components
  static double calculateProductCost({
    required double purchasePrice,
    required double transportCost,
    required double packagingCost,
    required double storageCost,
    required double marketingCost,
    required double damageCost,
    required double otherCosts,
  }) {
    return purchasePrice +
        transportCost +
        packagingCost +
        storageCost +
        marketingCost +
        damageCost +
        otherCosts;
  }

  /// sellingPrice = productCost + (productCost * profitMargin / 100)
  static double calculateSellingPrice({
    required double productCost,
    required double profitMargin,
  }) {
    return productCost + (productCost * profitMargin / 100);
  }

  /// profit = sellingPrice - productCost
  static double calculateProfit({
    required double sellingPrice,
    required double productCost,
  }) {
    return sellingPrice - productCost;
  }

  /// Create with auto-calculated fields
  factory GadgetStock.create({
    required String userId,
    required DateTime date,
    required String productCode,
    required String productName,
    required int quantity,
    required double purchasePrice,
    double transportCost = 0,
    double packagingCost = 0,
    double storageCost = 0,
    double marketingCost = 0,
    double damageCost = 0,
    double otherCosts = 0,
    required double profitMargin,
    double? sellingPriceOverride,
  }) {
    final now = DateTime.now();
    final productCost = calculateProductCost(
      purchasePrice: purchasePrice,
      transportCost: transportCost,
      packagingCost: packagingCost,
      storageCost: storageCost,
      marketingCost: marketingCost,
      damageCost: damageCost,
      otherCosts: otherCosts,
    );

    final sellingPrice =
        sellingPriceOverride ??
        calculateSellingPrice(
          productCost: productCost,
          profitMargin: profitMargin,
        );

    final profit = calculateProfit(
      sellingPrice: sellingPrice,
      productCost: productCost,
    );

    String stockStatus = 'in_stock';
    if (quantity == 0) {
      stockStatus = 'out_of_stock';
    } else if (quantity <= 5) {
      stockStatus = 'low_stock';
    }

    return GadgetStock(
      id: '',
      userId: userId,
      date: date,
      productCode: productCode,
      productName: productName,
      quantity: quantity,
      purchasePrice: purchasePrice,
      transportCost: transportCost,
      packagingCost: packagingCost,
      storageCost: storageCost,
      marketingCost: marketingCost,
      damageCost: damageCost,
      otherCosts: otherCosts,
      productCost: productCost,
      profitMargin: profitMargin,
      sellingPrice: sellingPrice,
      profit: profit,
      stockStatus: stockStatus,
      createdAt: now,
      updatedAt: now,
    );
  }
}
