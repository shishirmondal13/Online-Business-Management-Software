import 'package:intl/intl.dart';

/// Utility class for business calculations
class Calculations {
  Calculations._();

  /// Round value to exactly 2 decimal places to prevent floating-point precision errors
  static double _roundCurrency(double value) {
    if (value.isNaN || value.isInfinite) return 0.0;
    return double.parse(value.toStringAsFixed(2));
  }

  /// Calculate net purchase price for mobile stock
  /// netPurchasePrice = purchaseRate + transportCost
  static double calculateNetPurchasePrice({
    required double purchaseRate,
    required double transportCost,
  }) {
    return _roundCurrency(purchaseRate + transportCost);
  }

  /// Calculate profit for mobile stock
  /// profit = sellingPrice - netPurchasePrice
  static double calculateMobileProfit({
    required double sellingPrice,
    required double netPurchasePrice,
  }) {
    return _roundCurrency(sellingPrice - netPurchasePrice);
  }

  /// Calculate product cost for gadget stock
  /// productCost = purchasePrice + transportCost + packagingCost + storageCost +
  ///               marketingCost + damageCost + otherCosts
  static double calculateProductCost({
    required double purchasePrice,
    required double transportCost,
    required double packagingCost,
    required double storageCost,
    required double marketingCost,
    required double damageCost,
    required double otherCosts,
  }) {
    return _roundCurrency(
      purchasePrice +
          transportCost +
          packagingCost +
          storageCost +
          marketingCost +
          damageCost +
          otherCosts,
    );
  }

  /// Calculate selling price for gadget
  /// sellingPrice = productCost + (productCost * profitMargin/100)
  static double calculateSellingPrice({
    required double productCost,
    required double profitMargin,
  }) {
    return _roundCurrency(
      productCost + (productCost * (profitMargin / 100)),
    );
  }

  /// Calculate profit for gadget stock
  /// profit = sellingPrice - productCost
  static double calculateGadgetProfit({
    required double sellingPrice,
    required double productCost,
  }) {
    return _roundCurrency(sellingPrice - productCost);
  }

  /// Calculate per gram price from per kg price
  /// perGramPrice = perKgPrice / 1000
  static double calculatePerGramPrice({required double perKgPrice}) {
    return perKgPrice / 1000.0; // Higher precision needed mid-calculation
  }

  /// Calculate transport cost from weight
  /// transportCost = perGramPrice * productWeightGrams
  static double calculateTransportCost({
    required double perGramPrice,
    required double productWeightGrams,
  }) {
    return _roundCurrency(perGramPrice * productWeightGrams);
  }

  /// Calculate total sale amount
  /// totalAmount = sellingPrice * quantity
  static double calculateTotalAmount({
    required double sellingPrice,
    required int quantity,
  }) {
    return _roundCurrency(sellingPrice * quantity);
  }

  /// Calculate due amount
  /// dueAmount = totalAmount - paidAmount
  static double calculateDueAmount({
    required double totalAmount,
    required double paidAmount,
  }) {
    return _roundCurrency(totalAmount - paidAmount);
  }

  /// Calculate remaining due for customer
  /// remainingDue = totalDue - totalPaid
  static double calculateRemainingDue({
    required double totalDue,
    required double totalPaid,
  }) {
    return _roundCurrency(totalDue - totalPaid);
  }

  /// Calculate available capital
  /// availableCapital = initialCapital + capitalRecovered - capitalInvested
  static double calculateAvailableCapital({
    required double initialCapital,
    required double capitalRecovered,
    required double capitalInvested,
  }) {
    return _roundCurrency(initialCapital + capitalRecovered - capitalInvested);
  }

  /// Calculate profit margin percentage
  /// profitMargin = ((sellingPrice - cost) / cost) * 100
  static double calculateProfitMargin({
    required double sellingPrice,
    required double cost,
  }) {
    if (cost <= 0) {
      if (sellingPrice > 0) return 100.0;
      return 0.0;
    }
    return _roundCurrency(((sellingPrice - cost) / cost) * 100.0);
  }

  /// Calculate final profit from sales report
  /// profit = totalSales - totalCost + otherGains
  static double calculateFinalProfit({
    required double totalSales,
    required double totalCost,
    required double otherGains,
  }) {
    return _roundCurrency(totalSales - totalCost + otherGains);
  }
}

/// Utility class for formatting values
class Formatters {
  Formatters._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '৳',
    decimalDigits: 2,
    locale: 'bn_BD',
  );

  static final NumberFormat _numberFormat = NumberFormat('#,##0.##');

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy hh:mm a');
  static final DateFormat _monthFormat = DateFormat('MMMM yyyy');

  /// Format amount as currency (Taka)
  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  /// Format number with thousand separators
  static String formatNumber(double number) {
    return _numberFormat.format(number);
  }

  /// Format date
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Format date with time
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Format month and year
  static String formatMonth(DateTime date) {
    return _monthFormat.format(date);
  }

  /// Format percentage
  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(2)}%';
  }

  /// Format IMEI number with spaces for readability
  static String formatImei(String imei) {
    if (imei.length != 15) return imei;
    return '${imei.substring(0, 4)} ${imei.substring(4, 8)} ${imei.substring(8, 12)} ${imei.substring(12)}';
  }

  /// Parse currency string to double
  static double parseCurrency(String value) {
    try {
      if (value.trim().isEmpty) return 0.0;
      // Allow minus sign for negative amounts (refunds/advances)
      final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '');
      if (cleaned.isEmpty || cleaned == '-') return 0.0;
      return double.tryParse(cleaned) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }
}
