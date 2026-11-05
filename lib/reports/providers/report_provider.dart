import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/constants/firestore_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mobile_sector/models/mobile_stock.dart';
import '../../sales/models/sale.dart';
import '../services/export_service.dart';
import '../../shared/services/firestore_helpers.dart';
import '../../returns/models/return_transaction.dart';
import '../../shared/utils/calculations.dart';

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
  final double totalReturns;

  const ReportStats({
    this.totalSales = 0,
    this.mobileStockValue = 0,
    this.gadgetStockValue = 0,
    this.totalProfit = 0,
    this.totalLoss = 0,
    this.totalBuyingCost = 0,
    this.operatingExpenses = 0,
    this.totalReturns = 0,
  });

  double get totalCost => totalBuyingCost + operatingExpenses;
  double get netProfit => totalProfit - totalLoss - operatingExpenses;
}

class ReportFilter {
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? sector;

  ReportFilter({this.fromDate, this.toDate, this.sector});

  bool contains(DateTime date) =>
      ReportDateRange(fromDate: fromDate, toDate: toDate).contains(date);

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
      double totalReturns = 0;
      final salesById = <String, Sale>{};

      // 1. Calculate Mobile Metrics
      if (filter.sector == null || filter.sector == 'mobile') {
        final mobileSalesSnapshot = await firestore
            .collection(FirestoreConstants.sales)
            .where(FirestoreConstants.productType, isEqualTo: 'mobile')
            .get();

        for (final doc in mobileSalesSnapshot.docs) {
          final sale = Sale.fromFirestore(doc);
          salesById[sale.id] = sale;

          if (!filter.contains(sale.date)) {
            continue;
          }

          totalSales += sale.totalAmount;
          totalBuyingCost += sale.totalAmount - sale.profit;

          if (sale.profit > 0) {
            totalProfit += sale.profit;
          } else {
            totalLoss += sale.profit.abs();
          }
        }
      }

      // 2. Calculate Gadget Metrics
      if (filter.sector == null || filter.sector == 'gadget') {
        final gadgetSalesSnapshot = await firestore
            .collection(FirestoreConstants.sales)
            .where(FirestoreConstants.productType, isEqualTo: 'gadget')
            .get();

        for (final doc in gadgetSalesSnapshot.docs) {
          final sale = Sale.fromFirestore(doc);
          salesById[sale.id] = sale;

          if (!filter.contains(sale.date)) {
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

      // 2b. Apply return refunds and damage losses without deleting the sale.
      final returnSnapshot = await firestore
          .collection(FirestoreConstants.returns)
          .get();
      for (final doc in returnSnapshot.docs) {
        final returned = ReturnTransaction.fromFirestore(doc);
        if (!filter.contains(returned.date)) {
          continue;
        }
        if (filter.sector != null && filter.sector != returned.productType) {
          continue;
        }
        totalReturns += returned.refundAmount;
        if (returned.productType == FirestoreConstants.gadget ||
            returned.productType == FirestoreConstants.mobile) {
          final sale = salesById[returned.saleId];
          final unitProfit = sale == null || sale.quantity == 0
              ? 0.0
              : sale.profit / sale.quantity;
          final unitCost = sale == null ? 0.0 : sale.sellingPrice - unitProfit;
          totalSales -= returned.refundAmount;
          totalBuyingCost -= unitCost * returned.quantity;
          if (returned.condition == 'resalable') {
            totalProfit += unitCost * returned.quantity - returned.refundAmount;
          } else {
            totalProfit -= returned.refundAmount;
            totalLoss += unitCost * returned.quantity;
          }
        }
      }

      final damageSnapshot = await firestore
          .collection(FirestoreConstants.damageEvents)
          .get();
      for (final doc in damageSnapshot.docs) {
        final data = doc.data();
        final date = FirestoreHelpers.parseTimestamp(data['date']);
        if (date == null || !filter.contains(date)) {
          continue;
        }
        if (filter.sector != null && filter.sector != data['productType']) {
          continue;
        }
        totalLoss += (data['damageValue'] ?? 0).toDouble();
      }

      // 3. Calculate Salaries
      if (filter.sector == null) {
        final salarySnapshot = await firestore
            .collection(FirestoreConstants.salary)
            .get();
        for (final doc in salarySnapshot.docs) {
          final data = doc.data();
          final date = FirestoreHelpers.parseTimestamp(data['date']);
          if (date == null) {
            continue;
          }

          if (!filter.contains(date)) {
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

      // 4. Calculate Other Expenses
      if (filter.sector == null) {
        final expenseSnapshot = await firestore
            .collection(FirestoreConstants.expenses)
            .get();
        for (final doc in expenseSnapshot.docs) {
          final data = doc.data();
          final date = FirestoreHelpers.parseTimestamp(data['date']);
          if (date == null) {
            continue;
          }

          if (!filter.contains(date)) {
            continue;
          }

          totalExpenses += (data['amount'] ?? 0).toDouble();
        }
      }

      // 5. Calculate Unsold Stock Values
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
        totalReturns: totalReturns,
      );
    });

final lossHistoryProvider =
    FutureProvider.family<List<ReportItem>, ReportFilter>((ref, filter) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) return [];

      final firestore = FirebaseFirestore.instance;
      final List<ReportItem> items = [];

      // 1. Fetch Mobile Stock Loss
      if (filter.sector == null || filter.sector == 'mobile') {
        final mobileSalesSnapshot = await firestore
            .collection(FirestoreConstants.sales)
            .where(FirestoreConstants.productType, isEqualTo: 'mobile')
            .get();

        for (final doc in mobileSalesSnapshot.docs) {
          final sale = Sale.fromFirestore(doc);
          if (!filter.contains(sale.date)) {
            continue;
          }

          if (sale.profit < 0) {
            items.add(
              ReportItem(
                name: sale.productName,
                amount: sale.profit.abs(),
                date: sale.date,
                type: 'mobile',
              ),
            );
          }
        }
      }

      // 2. Fetch Gadget Loss
      if (filter.sector == null || filter.sector == 'gadget') {
        final salesSnapshot = await firestore
            .collection(FirestoreConstants.sales)
            .where(FirestoreConstants.productType, isEqualTo: 'gadget')
            .get();

        for (final doc in salesSnapshot.docs) {
          final sale = Sale.fromFirestore(doc);
          if (!filter.contains(sale.date)) {
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

      // 1. Fetch Mobile Stock Profit
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
          final eventDate = mobile.soldDate ?? mobile.date;
          if (!filter.contains(eventDate)) {
            continue;
          }

          final profit = mobile.sellingPrice - mobile.netPurchasePrice;
          if (profit >= 0) {
            items.add(
              ReportItem(
                name: '${mobile.modelName} (IMEI: ${mobile.imeiNumber})',
                amount: profit,
                date: eventDate,
                type: 'mobile',
              ),
            );
          }
        }
      }

      // 2. Fetch Gadget Profit
      if (filter.sector == null || filter.sector == 'gadget') {
        final salesSnapshot = await firestore
            .collection(FirestoreConstants.sales)
            .where(FirestoreConstants.productType, isEqualTo: 'gadget')
            .get();

        for (final doc in salesSnapshot.docs) {
          final sale = Sale.fromFirestore(doc);
          if (!filter.contains(sale.date)) {
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
