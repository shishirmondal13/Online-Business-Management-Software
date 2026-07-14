import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/constants/firestore_constants.dart';
import '../../mobile_sector/providers/mobile_provider.dart';
import '../../gadget_sector/providers/gadget_provider.dart';
import '../../sales/providers/sales_provider.dart';
import '../../capital/providers/capital_provider.dart';
import '../../salary/providers/salary_provider.dart';
import '../../expenses/providers/expense_provider.dart';

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
  final double totalSalaryPaid;
  final double totalOtherExpenses;

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
    this.totalSalaryPaid = 0,
    this.totalOtherExpenses = 0,
  });

  /// Total Assets (Real-Time Total Capital)
  double get totalCapital =>
      mobileStockValue + gadgetStockValue + availableCapital + totalBaki;

  /// Net Business Profit = Gross Profit - Gross Loss - Salaries - Expenses
  double get netProfit =>
      totalProfit - totalLoss - totalSalaryPaid - totalOtherExpenses;
}

/// Dashboard data provider - watches all relevant providers for real-time updates
final dashboardDataProvider = Provider<AsyncValue<DashboardData>>((ref) {
  final mobileStockAsync = ref.watch(mobileStockListProvider);
  final gadgetStockAsync = ref.watch(gadgetStockListProvider);
  final salesAsync = ref.watch(salesListProvider);
  final customersAsync = ref.watch(allCustomersProvider);
  final capitalAsync = ref.watch(capitalProvider);
  final salaryAsync = ref.watch(salaryListProvider);
  final expensesAsync = ref.watch(expenseListProvider);

  // If any provider is in error state and has no cached value, return that error
  final errorProvider = [
    mobileStockAsync,
    gadgetStockAsync,
    salesAsync,
    customersAsync,
    capitalAsync,
    salaryAsync,
    expensesAsync,
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

  // 1. Calculate mobile data
  double mobileStockValue = 0;
  int mobileUnsoldCount = 0;
  for (final item in mobileStock) {
    if (item.status == FirestoreConstants.unsold) {
      mobileStockValue += item.netPurchasePrice;
      mobileUnsoldCount++;
    }
  }

  // 2. Calculate gadget data
  double gadgetStockValue = 0;
  int gadgetTotalQuantity = 0;
  for (final item in gadgetStock) {
    gadgetStockValue += (item.productCost * item.quantity);
    gadgetTotalQuantity += item.quantity;
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
  int mobileUnitsSold = 0;
  int gadgetUnitsSold = 0;

  // 3.1 Mobile metrics (from mobileStock collection where status is sold)
  for (final item in mobileStock) {
    if (item.status == FirestoreConstants.sold) {
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

  // 3.2 Gadget metrics (from sales collection where type is gadget)
  for (final sale in sales) {
    if (sale.productType == 'gadget') {
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

  // Aggregate totals
  totalSales = mobileSales + gadgetSales;
  totalProfit = mobileProfit + gadgetProfit;
  totalLoss = mobileLoss + gadgetLoss;

  // 4. Calculate total debt (Baki)
  double totalBaki = 0;
  for (final customer in customers) {
    totalBaki += customer.remainingDue;
  }

  // 5. Calculate Capital & Investment
  double initialCapital = latestCapital?.initialCapital ?? 0;
  double capitalInvested = latestCapital?.capitalInvested ?? 0;
  final investment = (initialCapital + capitalInvested).abs();

  // 6. Calculate Expenses
  double totalSalaryPaid = 0;
  for (final p in salaryPayments) {
    totalSalaryPaid +=
        (p.amount + p.duePaid + p.advance + p.bonus) - p.deductions;
  }

  double totalOtherExpenses = 0;
  for (final e in otherExpenses) {
    totalOtherExpenses += e.amount;
  }

  // Business Rules:
  // Gross Sales Profit = sum of all positive sale profits
  // Gross Sales Loss = sum of all abs(negative sale profits)
  // Net Business Profit is computed dynamically: totalProfit - totalLoss - salary - expenses

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
      totalSalaryPaid: totalSalaryPaid,
      totalOtherExpenses: totalOtherExpenses,
    ),
  );
});
