import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/constants/firestore_constants.dart';
import '../../mobile_sector/providers/mobile_provider.dart';
import '../../gadget_sector/providers/gadget_provider.dart';
import '../../sales/providers/sales_provider.dart';
import '../../sales/models/sale.dart';
import '../../capital/providers/capital_provider.dart';
import '../../salary/providers/salary_provider.dart';
import '../../expenses/providers/expense_provider.dart';
import '../../returns/providers/return_provider.dart';

/// Dashboard Filter model for date/month/year filtering
class DashboardFilter {
  final DateTime? fromDate;
  final DateTime? toDate;
  final String label;

  const DashboardFilter({this.fromDate, this.toDate, this.label = 'All Time'});

  bool get isFiltered => fromDate != null || toDate != null;

  bool isWithinRange(DateTime date) {
    if (fromDate != null && date.isBefore(fromDate!)) return false;
    if (toDate != null) {
      final endOfDay = DateTime(
        toDate!.year,
        toDate!.month,
        toDate!.day,
        23,
        59,
        59,
        999,
      );
      if (date.isAfter(endOfDay)) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardFilter &&
          runtimeType == other.runtimeType &&
          fromDate == other.fromDate &&
          toDate == other.toDate &&
          label == other.label;

  @override
  int get hashCode => Object.hash(fromDate, toDate, label);
}

/// Active Dashboard date filter provider
final dashboardFilterProvider = StateProvider<DashboardFilter>((ref) {
  return const DashboardFilter(label: 'All Time');
});

/// Dashboard data model
class DashboardData {
  final double availableCapital;
  final double capitalInvested;
  final double totalProfit; // Gross sales profit only
  final double totalLoss; // Gross sales loss only
  final double totalBaki;
  final double totalSales;
  final double totalRevenue;
  final double mobileStockValue;
  final int mobileUnsoldCount;
  final double gadgetStockValue;
  final int gadgetTotalQuantity;
  final double mobileSales;
  final double mobileProfit;
  final double mobileLoss;
  final double gadgetSales;
  final double gadgetProfit;
  final double gadgetLoss;
  final int mobileUnitsSold;
  final int gadgetUnitsSold;
  final int mobileReturnedCount;
  final int gadgetReturnedQuantity;
  final double mobileReturnedValue;
  final double gadgetReturnedValue;
  final int mobileDamagedCount;
  final double mobileDamagedValue;
  final int gadgetDamagedQuantity;
  final double gadgetDamagedValue;
  final double totalSalaryPaid;
  final double totalOtherExpenses;
  final DashboardFilter filter;

  const DashboardData({
    this.availableCapital = 0,
    this.capitalInvested = 0,
    this.totalProfit = 0,
    this.totalLoss = 0,
    this.totalBaki = 0,
    this.totalSales = 0,
    this.totalRevenue = 0,
    this.mobileStockValue = 0,
    this.mobileUnsoldCount = 0,
    this.gadgetStockValue = 0,
    this.gadgetTotalQuantity = 0,
    this.mobileSales = 0,
    this.mobileProfit = 0,
    this.mobileLoss = 0,
    this.gadgetSales = 0,
    this.gadgetProfit = 0,
    this.gadgetLoss = 0,
    this.mobileUnitsSold = 0,
    this.gadgetUnitsSold = 0,
    this.mobileReturnedCount = 0,
    this.gadgetReturnedQuantity = 0,
    this.mobileReturnedValue = 0,
    this.gadgetReturnedValue = 0,
    this.mobileDamagedCount = 0,
    this.mobileDamagedValue = 0,
    this.gadgetDamagedQuantity = 0,
    this.gadgetDamagedValue = 0,
    this.totalSalaryPaid = 0,
    this.totalOtherExpenses = 0,
    this.filter = const DashboardFilter(),
  });

  /// Total Damage Loss = Mobile Damaged Value + Gadget Damaged Value
  double get totalDamageLoss => mobileDamagedValue + gadgetDamagedValue;

  /// Total Assets (Real-Time Total Capital)
  double get totalCapital =>
      mobileStockValue + gadgetStockValue + availableCapital + totalBaki;

  /// Net Business Profit = Gross Profit - Gross Loss - Salaries - Expenses
  double get netProfit =>
      totalProfit - totalLoss - totalSalaryPaid - totalOtherExpenses;
}

/// Dashboard data provider - watches all relevant providers for real-time updates
final dashboardDataProvider = Provider<AsyncValue<DashboardData>>((ref) {
  final filter = ref.watch(dashboardFilterProvider);
  final mobileStockAsync = ref.watch(mobileStockListProvider);
  final gadgetStockAsync = ref.watch(gadgetStockListProvider);
  final salesAsync = ref.watch(salesListProvider);
  final customersAsync = ref.watch(allCustomersProvider);
  final capitalAsync = ref.watch(capitalProvider);
  final salaryAsync = ref.watch(salaryListProvider);
  final expensesAsync = ref.watch(expenseListProvider);
  final returnsAsync = ref.watch(returnListProvider);
  final damageEventsAsync = ref.watch(damageEventListProvider);

  // If any provider is in error state and has no cached value, return that error
  final errorProvider = [
    mobileStockAsync,
    gadgetStockAsync,
    salesAsync,
    customersAsync,
    capitalAsync,
    salaryAsync,
    expensesAsync,
    returnsAsync,
    damageEventsAsync,
  ].firstWhere((p) => p.hasError && !p.hasValue, orElse: () => salesAsync);

  if (errorProvider.hasError && !errorProvider.hasValue) {
    return AsyncValue.error(errorProvider.error!, errorProvider.stackTrace!);
  }

  // If any provider is loading for the first time (no cached value), return loading
  final isLoading = [
    mobileStockAsync,
    gadgetStockAsync,
    salesAsync,
    customersAsync,
    capitalAsync,
    salaryAsync,
    expensesAsync,
    returnsAsync,
    damageEventsAsync,
  ].any((p) => p.isLoading && !p.hasValue);

  if (isLoading) {
    return const AsyncValue.loading();
  }

  // Extract data (fall back to empty lists/null if data not yet available)
  final mobileStock = mobileStockAsync.value ?? [];
  final gadgetStock = gadgetStockAsync.value ?? [];
  final sales = salesAsync.value ?? [];
  final customers = customersAsync.value ?? [];
  final latestCapital = capitalAsync.value;
  final salaryPayments = salaryAsync.value ?? [];
  final otherExpenses = expensesAsync.value ?? [];
  final returns = returnsAsync.value ?? [];
  final damageEvents = damageEventsAsync.value ?? [];

  // 1. Calculate mobile data
  double mobileStockValue = 0;
  int mobileUnsoldCount = 0;
  int mobileReturnedCount = 0;
  double mobileReturnedValue = 0;
  int mobileDamagedCount = 0;
  double mobileDamagedValue = 0;
  for (final item in mobileStock) {
    if (item.status == FirestoreConstants.unsold) {
      if (filter.isWithinRange(item.date)) {
        mobileStockValue += item.netPurchasePrice;
        mobileUnsoldCount++;
      }
    }
    if (item.isReturned || item.returnCount > 0) {
      if (filter.isWithinRange(item.returnedAt ?? item.date)) {
        mobileReturnedCount++;
        mobileReturnedValue += item.netPurchasePrice;
      }
    }
    if (item.status == 'damaged' || item.isDamaged) {
      if (filter.isWithinRange(item.date)) {
        mobileDamagedCount++;
        mobileDamagedValue += item.netPurchasePrice;
      }
    }
  }

  // 2. Calculate gadget data
  double gadgetStockValue = 0;
  int gadgetTotalQuantity = 0;
  int gadgetReturnedQuantity = 0;
  double gadgetReturnedValue = 0;
  int gadgetDamagedQuantity = 0;
  double gadgetDamagedValue = 0;
  for (final item in gadgetStock) {
    if (filter.isWithinRange(item.date)) {
      gadgetStockValue += (item.productCost * item.quantity);
      gadgetTotalQuantity += item.quantity;
    }
    if (item.isReturned || item.returnedQuantity > 0) {
      if (filter.isWithinRange(item.returnedAt ?? item.date)) {
        final qty = item.returnedQuantity > 0 ? item.returnedQuantity : 1;
        gadgetReturnedQuantity += qty;
        gadgetReturnedValue += (item.productCost * qty);
      }
    }
    if (item.damagedQuantity > 0) {
      if (filter.isWithinRange(item.date)) {
        gadgetDamagedQuantity += item.damagedQuantity;
        gadgetDamagedValue += (item.damageValue > 0
            ? item.damageValue
            : item.productCost * item.damagedQuantity);
      }
    }
  }

  // 3. Calculate sales metrics
  double totalSales = 0;
  double totalProfit = 0;
  double totalLoss = 0;
  double mobileSales = 0;
  double mobileProfit = 0;
  double mobileLoss = 0;
  double gadgetSales = 0;
  double gadgetProfit = 0;
  double gadgetLoss = 0;
  double damageEventLoss = 0;
  int mobileUnitsSold = 0;
  int gadgetUnitsSold = 0;

  // 3.1 Mobile metrics (from mobileStock collection where status is sold)
  for (final item in mobileStock) {
    if (item.status == FirestoreConstants.sold) {
      if (filter.isWithinRange(item.soldDate ?? item.date)) {
        final profit = item.sellingPrice - item.netPurchasePrice;
        mobileSales += item.sellingPrice;
        mobileUnitsSold++;

        if (profit > 0) {
          mobileProfit += profit;
        } else {
          mobileLoss += profit.abs();
        }
      }
    }
  }

  // 3.2 Gadget metrics (from sales collection where type is gadget)
  for (final sale in sales) {
    if (sale.productType == 'gadget') {
      if (filter.isWithinRange(sale.date)) {
        final saleTotal = sale.totalAmount;
        final saleProfit = sale.profit;
        final saleQty = sale.quantity;

        gadgetSales += saleTotal;
        gadgetUnitsSold += saleQty;

        if (saleProfit > 0) {
          gadgetProfit += saleProfit;
        } else {
          gadgetLoss += saleProfit.abs();
        }
      }
    }
  }

  // Returns reduce revenue. For gadgets, resalable returns also restore COGS;
  // damaged returns remain a loss at product cost. Mobile sales are derived
  // from current mobile status, so a returned mobile is already excluded.
  for (final returned in returns) {
    if (returned.productType != FirestoreConstants.gadget ||
        !filter.isWithinRange(returned.date)) {
      continue;
    }
    Sale? matchingSale;
    for (final sale in sales) {
      if (sale.id == returned.saleId) {
        matchingSale = sale;
        break;
      }
    }
    final unitProfit = matchingSale == null || matchingSale.quantity == 0
        ? 0.0
        : matchingSale.profit / matchingSale.quantity;
    final unitCost = matchingSale == null
        ? 0.0
        : matchingSale.sellingPrice - unitProfit;
    gadgetSales -= returned.refundAmount;
    if (returned.condition == 'resalable') {
      gadgetProfit += (unitCost * returned.quantity) - returned.refundAmount;
    } else {
      gadgetProfit -= returned.refundAmount;
      gadgetLoss += unitCost * returned.quantity;
    }
  }

  for (final event in damageEvents) {
    if (filter.isWithinRange(event.date)) {
      damageEventLoss += event.damageValue;
    }
  }

  // Aggregate totals
  totalSales = mobileSales + gadgetSales;
  totalProfit = mobileProfit + gadgetProfit;
  totalLoss = mobileLoss + gadgetLoss + damageEventLoss;

  // 4. Calculate total debt (Baki)
  double totalBaki = 0;
  for (final customer in customers) {
    if (!filter.isFiltered || filter.isWithinRange(customer.createdAt)) {
      totalBaki += customer.remainingDue;
    }
  }

  // 5. Calculate Capital & Investment
  double initialCapital = latestCapital?.initialCapital ?? 0;
  double capitalInvested = latestCapital?.capitalInvested ?? 0;
  final investment = initialCapital + capitalInvested;

  // 6. Calculate Expenses
  double totalSalaryPaid = 0;
  for (final p in salaryPayments) {
    if (filter.isWithinRange(p.date)) {
      totalSalaryPaid +=
          (p.amount + p.duePaid + p.advance + p.bonus) - p.deductions;
    }
  }

  double totalOtherExpenses = 0;
  for (final e in otherExpenses) {
    if (filter.isWithinRange(e.date)) {
      totalOtherExpenses += e.amount;
    }
  }

  // Total Revenue for display
  final totalRevenue = totalSales;

  // Available Cash (Trusting the availableCapital field which is updated by services)
  final userAvailableCapital = (latestCapital?.availableCapital ?? 0.0);

  return AsyncValue.data(
    DashboardData(
      availableCapital: userAvailableCapital,
      capitalInvested: investment,
      totalProfit: totalProfit, // Gross sales profit
      totalLoss: totalLoss, // Gross sales loss
      totalBaki: totalBaki,
      totalSales: totalSales,
      totalRevenue: totalRevenue,
      mobileStockValue: mobileStockValue,
      mobileUnsoldCount: mobileUnsoldCount,
      gadgetStockValue: gadgetStockValue,
      gadgetTotalQuantity: gadgetTotalQuantity,
      mobileSales: mobileSales,
      mobileProfit: mobileProfit,
      mobileLoss: mobileLoss,
      gadgetSales: gadgetSales,
      gadgetProfit: gadgetProfit,
      gadgetLoss: gadgetLoss,
      mobileUnitsSold: mobileUnitsSold,
      gadgetUnitsSold: gadgetUnitsSold,
      mobileReturnedCount: mobileReturnedCount,
      gadgetReturnedQuantity: gadgetReturnedQuantity,
      mobileReturnedValue: mobileReturnedValue,
      gadgetReturnedValue: gadgetReturnedValue,
      mobileDamagedCount: mobileDamagedCount,
      mobileDamagedValue: mobileDamagedValue,
      gadgetDamagedQuantity: gadgetDamagedQuantity,
      gadgetDamagedValue: gadgetDamagedValue,
      totalSalaryPaid: totalSalaryPaid,
      totalOtherExpenses: totalOtherExpenses,
      filter: filter,
    ),
  );
});
