import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/constants/firestore_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mobile_sector/models/mobile_stock.dart';
import '../../sales/models/sale.dart';
import '../services/export_service.dart';
import '../../shared/services/firestore_helpers.dart';

class ReportItem {
  final String name;
  final double amount;
  final DateTime date;
  final String type; // 'mobile' or 'gadget'

  ReportItem({
    required this.name,
    required this.amount,
    required this.date,
    required this.type,
  });
}

class ReportStats {
  final double totalSales;
  final double mobileStockValue;
  final double gadgetStockValue;
  final double totalProfit; // Gross profit from sales
  final double totalLoss; // Gross loss from sales
  final double totalBuyingCost; // COGS (Cost of Goods Sold)
  final double operatingExpenses; // Salaries + Other Expenses

  const ReportStats({
    this.totalSales = 0,
    this.mobileStockValue = 0,
    this.gadgetStockValue = 0,
    this.totalProfit = 0,
    this.totalLoss = 0,
    this.totalBuyingCost = 0,
    this.operatingExpenses = 0,
  });

  double get totalCost => totalBuyingCost + operatingExpenses;
  double get netProfit => totalProfit - totalLoss - operatingExpenses;
}

class ReportFilter {
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? sector;

  ReportFilter({this.fromDate, this.toDate, this.sector});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportFilter &&
        other.fromDate == fromDate &&
        other.toDate == toDate &&
        other.sector == sector;
  }

  @override
  int get hashCode => Object.hash(fromDate, toDate, sector);
}

final filteredReportStatsProvider =
    FutureProvider.family<ReportStats, ReportFilter>((ref, filter) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) return const ReportStats();

      final firestore = FirebaseFirestore.instance;
      double totalSales = 0;
      double totalProfit = 0;
      double totalLoss = 0;
      double totalBuyingCost = 0;
      double totalSalaries = 0;
      double totalExpenses = 0;
      double mobileStockValue = 0;
      double gadgetStockValue = 0;

      // 1. Calculate Mobile Metrics (filtered by userId)
      if (filter.sector == null || filter.sector == 'mobile') {
        final mobileSnapshot = await firestore
            .collection(FirestoreConstants.mobileStock)
            .where(
              FirestoreConstants.status,
              isEqualTo: FirestoreConstants.sold,
            )
            .get();

        for (final doc in mobileSnapshot.docs) {
          final mobile = MobileStock.fromFirestore(doc);

          if (filter.fromDate != null &&
              mobile.updatedAt.isBefore(filter.fromDate!)) {
            continue;
          }
          if (filter.toDate != null &&
              mobile.updatedAt.isAfter(
                filter.toDate!.add(const Duration(days: 1)),
              )) {
            continue;
          }

          final profit = mobile.sellingPrice - mobile.netPurchasePrice;
          totalSales += mobile.sellingPrice;
          totalBuyingCost += mobile.netPurchasePrice;

          if (profit > 0) {
            totalProfit += profit;
          } else {
            totalLoss += profit.abs();
          }
        }
      }

      // 2. Calculate Gadget Metrics (filtered by userId)
      if (filter.sector == null || filter.sector == 'gadget') {
        final gadgetSalesSnapshot = await firestore
            .collection(FirestoreConstants.sales)
            .where(FirestoreConstants.productType, isEqualTo: 'gadget')
            .get();

        for (final doc in gadgetSalesSnapshot.docs) {
          final sale = Sale.fromFirestore(doc);

          if (filter.fromDate != null && sale.date.isBefore(filter.fromDate!)) {
            continue;
          }
          if (filter.toDate != null &&
              sale.date.isAfter(filter.toDate!.add(const Duration(days: 1)))) {
            continue;
          }

          totalSales += sale.totalAmount;
          totalBuyingCost += (sale.totalAmount - sale.profit);

          if (sale.profit > 0) {
            totalProfit += sale.profit;
          } else {
            totalLoss += sale.profit.abs();
          }
        }
      }

      // 3. Calculate Salaries (filtered by userId)
      if (filter.sector == null) {
        final salarySnapshot = await firestore
            .collection(FirestoreConstants.salary)
            .get();
        for (final doc in salarySnapshot.docs) {
          final data = doc.data();
          final date = FirestoreHelpers.parseTimestamp(data['date']);
          if (date == null) continue;

          if (filter.fromDate != null && date.isBefore(filter.fromDate!)) {
            continue;
          }
          if (filter.toDate != null &&
              date.isAfter(filter.toDate!.add(const Duration(days: 1)))) {
            continue;
          }

          final amount = (data['amount'] ?? 0).toDouble();
          final duePaid = (data['duePaid'] ?? 0).toDouble();
          final advance = (data['advance'] ?? 0).toDouble();
          final bonus = (data['bonus'] ?? 0).toDouble();
          final deductions = (data['deductions'] ?? 0).toDouble();

          totalSalaries += (amount + duePaid + advance + bonus) - deductions;
        }
      }

      // 4. Calculate Other Expenses (filtered by userId)
      if (filter.sector == null) {
        final expenseSnapshot = await firestore
            .collection(FirestoreConstants.expenses)
            .get();
        for (final doc in expenseSnapshot.docs) {
          final data = doc.data();
          final date = FirestoreHelpers.parseTimestamp(data['date']);
          if (date == null) continue;

          if (filter.fromDate != null && date.isBefore(filter.fromDate!)) {
            continue;
          }
          if (filter.toDate != null &&
              date.isAfter(filter.toDate!.add(const Duration(days: 1)))) {
            continue;
          }

          totalExpenses += (data['amount'] ?? 0).toDouble();
        }
      }

      // 5. Calculate Unsold Stock Values (filtered by userId)
      if (filter.sector == null || filter.sector == 'mobile') {
        final mobileUnsoldSnapshot = await firestore
            .collection(FirestoreConstants.mobileStock)
            .where(
              FirestoreConstants.status,
              isEqualTo: FirestoreConstants.unsold,
            )
            .get();
        for (final doc in mobileUnsoldSnapshot.docs) {
          final mobile = MobileStock.fromFirestore(doc);
          mobileStockValue += mobile.netPurchasePrice;
        }
      }

      if (filter.sector == null || filter.sector == 'gadget') {
        final gadgetSnapshot = await firestore
            .collection(FirestoreConstants.gadgetStock)
            .get();
        for (final doc in gadgetSnapshot.docs) {
          final data = doc.data();
          final qty = ((data[FirestoreConstants.quantity] ?? 0) as num).toInt();
          final cost = (data[FirestoreConstants.productCost] ?? 0).toDouble();
          gadgetStockValue += (cost * qty);
        }
      }

      return ReportStats(
        totalSales: totalSales,
        mobileStockValue: mobileStockValue,
        gadgetStockValue: gadgetStockValue,
        totalProfit: totalProfit,
        totalLoss: totalLoss,
        totalBuyingCost: totalBuyingCost,
        operatingExpenses: totalSalaries + totalExpenses,
      );
    });

final lossHistoryProvider =
    FutureProvider.family<List<ReportItem>, ReportFilter>((ref, filter) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) return [];

      final firestore = FirebaseFirestore.instance;
      final List<ReportItem> items = [];

      // 1. Fetch Mobile Stock Loss (filtered by userId)
      if (filter.sector == null || filter.sector == 'mobile') {
        final mobileSnapshot = await firestore
            .collection(FirestoreConstants.mobileStock)
            .where(
              FirestoreConstants.status,
              isEqualTo: FirestoreConstants.sold,
            )
            .get();

        for (final doc in mobileSnapshot.docs) {
          final mobile = MobileStock.fromFirestore(doc);
          if (filter.fromDate != null &&
              mobile.updatedAt.isBefore(filter.fromDate!)) {
            continue;
          }
          if (filter.toDate != null &&
              mobile.updatedAt.isAfter(
                filter.toDate!.add(const Duration(days: 1)),
              )) {
            continue;
          }

          final profit = mobile.sellingPrice - mobile.netPurchasePrice;
          if (profit < 0) {
            items.add(
              ReportItem(
                name: '${mobile.modelName} (IMEI: ${mobile.imeiNumber})',
                amount: profit.abs(),
                date: mobile.updatedAt,
                type: 'mobile',
              ),
            );
          }
        }
      }

      // 2. Fetch Gadget Loss (filtered by userId)
      if (filter.sector == null || filter.sector == 'gadget') {
        final salesSnapshot = await firestore
            .collection(FirestoreConstants.sales)
            .where(FirestoreConstants.productType, isEqualTo: 'gadget')
            .get();

        for (final doc in salesSnapshot.docs) {
          final sale = Sale.fromFirestore(doc);
          if (filter.fromDate != null && sale.date.isBefore(filter.fromDate!)) {
            continue;
          }
          if (filter.toDate != null &&
              sale.date.isAfter(filter.toDate!.add(const Duration(days: 1)))) {
            continue;
          }

          if (sale.profit < 0) {
            items.add(
              ReportItem(
                name: sale.productName,
                amount: sale.profit.abs(),
                date: sale.date,
                type: 'gadget',
              ),
            );
          }
        }
      }

      items.sort((a, b) => b.date.compareTo(a.date));
      return items;
    });

final profitHistoryProvider =
    FutureProvider.family<List<ReportItem>, ReportFilter>((ref, filter) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) return [];

      final firestore = FirebaseFirestore.instance;
      final List<ReportItem> items = [];

      // 1. Fetch Mobile Stock Profit (filtered by userId)
      if (filter.sector == null || filter.sector == 'mobile') {
        final mobileSnapshot = await firestore
            .collection(FirestoreConstants.mobileStock)
            .where(
              FirestoreConstants.status,
              isEqualTo: FirestoreConstants.sold,
            )
            .get();

        for (final doc in mobileSnapshot.docs) {
          final mobile = MobileStock.fromFirestore(doc);
          if (filter.fromDate != null &&
              mobile.updatedAt.isBefore(filter.fromDate!)) {
            continue;
          }
          if (filter.toDate != null &&
              mobile.updatedAt.isAfter(
                filter.toDate!.add(const Duration(days: 1)),
              )) {
            continue;
          }

          final profit = mobile.sellingPrice - mobile.netPurchasePrice;
          if (profit >= 0) {
            items.add(
              ReportItem(
                name: '${mobile.modelName} (IMEI: ${mobile.imeiNumber})',
                amount: profit,
                date: mobile.updatedAt,
                type: 'mobile',
              ),
            );
          }
        }
      }

      // 2. Fetch Gadget Profit (filtered by userId)
      if (filter.sector == null || filter.sector == 'gadget') {
        final salesSnapshot = await firestore
            .collection(FirestoreConstants.sales)
            .where(FirestoreConstants.productType, isEqualTo: 'gadget')
            .get();

        for (final doc in salesSnapshot.docs) {
          final sale = Sale.fromFirestore(doc);
          if (filter.fromDate != null && sale.date.isBefore(filter.fromDate!)) {
            continue;
          }
          if (filter.toDate != null &&
              sale.date.isAfter(filter.toDate!.add(const Duration(days: 1)))) {
            continue;
          }

          if (sale.profit >= 0) {
            items.add(
              ReportItem(
                name: sale.productName,
                amount: sale.profit,
                date: sale.date,
                type: 'gadget',
              ),
            );
          }
        }
      }

      items.sort((a, b) => b.date.compareTo(a.date));
      return items;
    });

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});
