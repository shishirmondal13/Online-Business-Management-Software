import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/base_model.dart';

/// Sale model
class Sale extends BaseModel {
  final DateTime date;
  final String productType; // 'mobile' or 'gadget'
  final String productId;
  final String productName;
  final int quantity;
  final double sellingPrice;
  final double totalAmount;
  final String customerId;
  final String customerName;
  final String contactNumber;
  final String paymentStatus; // 'paid', 'partial', 'unpaid'
  final double paidAmount;
  final double dueAmount;
  final double profit;

  const Sale({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    required this.date,
    required this.productType,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.sellingPrice,
    required this.totalAmount,
    required this.customerId,
    required this.customerName,
    required this.contactNumber,
    required this.paymentStatus,
    required this.paidAmount,
    required this.dueAmount,
    required this.profit,
  });

  factory Sale.fromMap(Map<String, dynamic> map, String id) {
    return Sale(
      id: id,
      userId: map['userId'] ?? '',
      date: BaseModel.timestampToDate(map['date']),
      productType: map['productType'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: (map['quantity'] ?? 1).toInt(),
      sellingPrice: (map['sellingPrice'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      paymentStatus: map['paymentStatus'] ?? 'unpaid',
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      dueAmount: (map['dueAmount'] ?? 0).toDouble(),
      profit: (map['profit'] ?? 0).toDouble(),
      createdAt: BaseModel.timestampToDate(map['createdAt']),
      updatedAt: BaseModel.timestampToDate(map['updatedAt']),
    );
  }

  factory Sale.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Sale.fromMap(data, doc.id);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': BaseModel.dateToTimestamp(date),
      'productType': productType,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'sellingPrice': sellingPrice,
      'totalAmount': totalAmount,
      'customerId': customerId,
      'customerName': customerName,
      'contactNumber': contactNumber,
      'paymentStatus': paymentStatus,
      'paidAmount': paidAmount,
      'dueAmount': dueAmount,
      'profit': profit,
      'createdAt': BaseModel.dateToTimestamp(createdAt),
      'updatedAt': BaseModel.dateToTimestamp(updatedAt),
    };
  }

  Sale copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? productType,
    String? productId,
    String? productName,
    int? quantity,
    double? sellingPrice,
    double? totalAmount,
    String? customerId,
    String? customerName,
    String? contactNumber,
    String? paymentStatus,
    double? paidAmount,
    double? dueAmount,
    double? profit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Sale(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      productType: productType ?? this.productType,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      contactNumber: contactNumber ?? this.contactNumber,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAmount: paidAmount ?? this.paidAmount,
      dueAmount: dueAmount ?? this.dueAmount,
      profit: profit ?? this.profit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Sale.create({
    required String userId,
    required DateTime date,
    required String productType,
    required String productId,
    required String productName,
    required int quantity,
    required double sellingPrice,
    required String customerId,
    required String customerName,
    required String contactNumber,
    required double paidAmount,
    required double profit,
  }) {
    final now = DateTime.now();
    final totalAmount = sellingPrice * quantity;
    final dueAmount = totalAmount - paidAmount;
    String paymentStatus = 'unpaid';
    if (paidAmount >= totalAmount) {
      paymentStatus = 'paid';
    } else if (paidAmount > 0) {
      paymentStatus = 'partial';
    }

    return Sale(
      id: '',
      userId: userId,
      date: date,
      productType: productType,
      productId: productId,
      productName: productName,
      quantity: quantity,
      sellingPrice: sellingPrice,
      totalAmount: totalAmount,
      customerId: customerId,
      customerName: customerName,
      contactNumber: contactNumber,
      paymentStatus: paymentStatus,
      paidAmount: paidAmount,
      dueAmount: dueAmount,
      profit: profit,
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// Customer model
class Customer extends BaseModel {
  final String name;
  final String contactNumber;
  final double totalDue;
  final double totalPaid;
  final double remainingDue;

  const Customer({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    required this.name,
    required this.contactNumber,
    required this.totalDue,
    required this.totalPaid,
    required this.remainingDue,
  });

  factory Customer.fromMap(Map<String, dynamic> map, String id) {
    return Customer(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      totalDue: (map['totalDue'] ?? 0).toDouble(),
      totalPaid: (map['totalPaid'] ?? 0).toDouble(),
      remainingDue: (map['remainingDue'] ?? 0).toDouble(),
      createdAt: BaseModel.timestampToDate(map['createdAt']),
      updatedAt: BaseModel.timestampToDate(map['updatedAt']),
    );
  }

  factory Customer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Customer.fromMap(data, doc.id);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'contactNumber': contactNumber,
      'totalDue': totalDue,
      'totalPaid': totalPaid,
      'remainingDue': remainingDue,
      'createdAt': BaseModel.dateToTimestamp(createdAt),
      'updatedAt': BaseModel.dateToTimestamp(updatedAt),
    };
  }

  Customer copyWith({
    String? id,
    String? userId,
    String? name,
    String? contactNumber,
    double? totalDue,
    double? totalPaid,
    double? remainingDue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      contactNumber: contactNumber ?? this.contactNumber,
      totalDue: totalDue ?? this.totalDue,
      totalPaid: totalPaid ?? this.totalPaid,
      remainingDue: remainingDue ?? this.remainingDue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Payment model
class Payment extends BaseModel {
  final String customerId;
  final String saleId;
  final DateTime date;
  final double amount;
  final String paymentMethod;
  final String notes;

  const Payment({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    required this.customerId,
    required this.saleId,
    required this.date,
    required this.amount,
    required this.paymentMethod,
    required this.notes,
  });

  factory Payment.fromMap(Map<String, dynamic> map, String id) {
    return Payment(
      id: id,
      userId: map['userId'] ?? '',
      customerId: map['customerId'] ?? '',
      saleId: map['saleId'] ?? '',
      date: BaseModel.timestampToDate(map['date']),
      amount: (map['amount'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'cash',
      notes: map['notes'] ?? '',
      createdAt: BaseModel.timestampToDate(map['createdAt']),
      updatedAt: BaseModel.timestampToDate(map['updatedAt']),
    );
  }

  factory Payment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Payment.fromMap(data, doc.id);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'customerId': customerId,
      'saleId': saleId,
      'date': BaseModel.dateToTimestamp(date),
      'amount': amount,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'createdAt': BaseModel.dateToTimestamp(createdAt),
      'updatedAt': BaseModel.dateToTimestamp(updatedAt),
    };
  }
}
