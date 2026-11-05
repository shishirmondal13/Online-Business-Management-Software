import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/constants/firestore_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../sales/providers/sales_provider.dart';
import '../../sales/models/sale.dart';
import '../../expenses/providers/expense_provider.dart';
import '../../salary/providers/salary_provider.dart';
import '../../mobile_sector/providers/mobile_provider.dart';
import '../../gadget_sector/providers/gadget_provider.dart';
import '../../returns/providers/return_provider.dart';
import './investment_provider.dart';
import '../models/capital.dart';

final capitalBaseProvider = StreamProvider<Capital?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection(FirestoreConstants.capital)
      .snapshots()
      .map((snap) {
        final docs = snap.docs.map((d) => Capital.fromFirestore(d)).toList();
        if (docs.isEmpty) return null;

        // Aggregate values across all capital documents
        double totalInitial = 0;
        for (final doc in docs) {
          totalInitial += doc.initialCapital;
        }

        docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final latest = docs.first;

        return latest.copyWith(initialCapital: totalInitial);
      });
});

final capitalProvider = Provider<AsyncValue<Capital?>>((ref) {
  final baseCapitalAsync = ref.watch(capitalBaseProvider);
  final investmentsAsync = ref.watch(investmentHistoryProvider);
  final paymentsAsync = ref.watch(globalPaymentsProvider);
  final expensesAsync = ref.watch(expenseListProvider);
  final salariesAsync = ref.watch(salaryListProvider);
  final mobileStockAsync = ref.watch(mobileStockListProvider);
  final gadgetStockAsync = ref.watch(gadgetStockListProvider);
  final salesAsync = ref.watch(salesListProvider);
  final returnsAsync = ref.watch(returnListProvider);

  // Helper to handle combined loading/error state
  if ((baseCapitalAsync.isLoading && !baseCapitalAsync.hasValue) ||
      (investmentsAsync.isLoading && !investmentsAsync.hasValue) ||
      (paymentsAsync.isLoading && !paymentsAsync.hasValue) ||
      (expensesAsync.isLoading && !expensesAsync.hasValue) ||
      (salariesAsync.isLoading && !salariesAsync.hasValue) ||
      (mobileStockAsync.isLoading && !mobileStockAsync.hasValue) ||
      (gadgetStockAsync.isLoading && !gadgetStockAsync.hasValue) ||
      (salesAsync.isLoading && !salesAsync.hasValue) ||
      (returnsAsync.isLoading && !returnsAsync.hasValue)) {
    return const AsyncValue.loading();
  }

  if (baseCapitalAsync.hasError && !baseCapitalAsync.hasValue) {
    return AsyncValue.error(
      baseCapitalAsync.error!,
      baseCapitalAsync.stackTrace!,
    );
  }
  if (investmentsAsync.hasError && !investmentsAsync.hasValue) {
    return AsyncValue.error(
      investmentsAsync.error!,
      investmentsAsync.stackTrace!,
    );
  }
  if (paymentsAsync.hasError && !paymentsAsync.hasValue) {
    return AsyncValue.error(paymentsAsync.error!, paymentsAsync.stackTrace!);
  }
  if (expensesAsync.hasError && !expensesAsync.hasValue) {
    return AsyncValue.error(expensesAsync.error!, expensesAsync.stackTrace!);
  }
  if (salariesAsync.hasError && !salariesAsync.hasValue) {
    return AsyncValue.error(salariesAsync.error!, salariesAsync.stackTrace!);
  }
  if (mobileStockAsync.hasError && !mobileStockAsync.hasValue) {
    return AsyncValue.error(
      mobileStockAsync.error!,
      mobileStockAsync.stackTrace!,
    );
  }
  if (gadgetStockAsync.hasError && !gadgetStockAsync.hasValue) {
    return AsyncValue.error(
      gadgetStockAsync.error!,
      gadgetStockAsync.stackTrace!,
    );
  }
  if (salesAsync.hasError && !salesAsync.hasValue) {
    return AsyncValue.error(salesAsync.error!, salesAsync.stackTrace!);
  }
  if (returnsAsync.hasError && !returnsAsync.hasValue) {
    return AsyncValue.error(returnsAsync.error!, returnsAsync.stackTrace!);
  }

  final baseCapital =
      baseCapitalAsync.value ??
      Capital(
        id: '',
        userId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        initialCapital: 0,
        capitalInvested: 0,
        capitalRecovered: 0,
        availableCapital: 0,
        month: '',
      );

  final investments = investmentsAsync.value ?? [];
  final payments = paymentsAsync.value ?? [];
  final expenses = expensesAsync.value ?? [];
  final salaries = salariesAsync.value ?? [];
  final mobileStock = mobileStockAsync.value ?? [];
  final gadgetStock = gadgetStockAsync.value ?? [];
  final sales = salesAsync.value ?? [];
  final returns = returnsAsync.value ?? [];

  // Calculate dynamic investments
  double totalInvested = 0;
  for (final inv in investments) {
    if (inv.type == 'add') {
      totalInvested += inv.amount;
    } else if (inv.type == 'remove') {
      totalInvested -= inv.amount;
    }
  }

  // Calculate dynamic payments (sales revenue)
  double totalRecovered = 0;
  for (final pay in payments) {
    totalRecovered += pay.amount;
  }

  // Calculate dynamic expenses
  double totalExpenses = 0;
  for (final exp in expenses) {
    totalExpenses += exp.amount;
  }

  // Calculate dynamic salaries
  double totalSalaries = 0;
  for (final sal in salaries) {
    totalSalaries += sal.totalDeduction;
  }

  // Calculate total mobile purchase cost
  double totalMobilePurchased = 0;
  for (final mob in mobileStock) {
    totalMobilePurchased += mob.netPurchasePrice;
  }

  // Calculate total gadget purchase cost
  double totalGadgetPurchased = 0;
  for (final gad in gadgetStock) {
    totalGadgetPurchased += (gad.productCost * gad.quantity);
  }
  for (final sale in sales) {
    if (sale.productType == 'gadget') {
      totalGadgetPurchased += (sale.totalAmount - sale.profit);
    }
  }
  for (final returned in returns) {
    if (returned.productType != 'gadget' || returned.condition != 'resalable') {
      continue;
    }
    Sale? matchingSale;
    for (final sale in sales) {
      if (sale.id == returned.saleId) {
        matchingSale = sale;
        break;
      }
    }
    if (matchingSale == null || matchingSale.quantity <= 0) continue;
    final unitCost =
        (matchingSale.totalAmount - matchingSale.profit) /
        matchingSale.quantity;
    totalGadgetPurchased -= unitCost * returned.quantity;
  }

  // Available Capital = Initial Capital + Investments + Payments - Expenses - Salaries - Mobile Purchase Cost - Gadget Purchase Cost
  final totalAvailable =
      baseCapital.initialCapital +
      totalInvested +
      totalRecovered -
      totalExpenses -
      totalSalaries -
      totalMobilePurchased -
      totalGadgetPurchased;

  return AsyncValue.data(
    baseCapital.copyWith(
      capitalInvested: totalInvested,
      capitalRecovered: totalRecovered,
      availableCapital: totalAvailable,
    ),
  );
});

final capitalServiceProvider = Provider<CapitalService>(
  (ref) => CapitalService(),
);

class CapitalService {
  final _firestore = FirebaseFirestore.instance;

  Future<void> saveCapital(Capital capital) async {
    final month = capital.month;

    // Check if exists for this month
    final existing = await _firestore
        .collection(FirestoreConstants.capital)
        .where(FirestoreConstants.userId, isEqualTo: capital.userId)
        .where('month', isEqualTo: month)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      await _firestore
          .collection(FirestoreConstants.capital)
          .doc(existing.docs.first.id)
          .update(
            capital
                .copyWith(id: existing.docs.first.id, updatedAt: DateTime.now())
                .toMap(),
          );
    } else {
      final id = _firestore.collection(FirestoreConstants.capital).doc().id;
      await _firestore
          .collection(FirestoreConstants.capital)
          .doc(id)
          .set(capital.copyWith(id: id).toMap());
    }
  }
}
