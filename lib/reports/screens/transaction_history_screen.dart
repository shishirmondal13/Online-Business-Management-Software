import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/constants/app_colors.dart';
import '../../sales/providers/sales_provider.dart';
import '../../salary/providers/salary_provider.dart';
import '../../expenses/providers/expense_provider.dart';
import '../../expenses/models/expense.dart';
import '../../salary/models/salary_payment.dart';
import '../../sales/models/sale.dart';
import '../../auth/providers/auth_provider.dart';
import '../../reports/screens/edit_transaction_dialog.dart';
import '../../shared/utils/calculations.dart';
import '../../admin/providers/admin_provider.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const TransactionHistoryScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transaction History'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Sales'),
            Tab(text: 'Expenses'),
            Tab(text: 'Salaries'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _SalesListTab(),
          _ExpensesListTab(),
          _SalariesListTab(),
        ],
      ),
    );
  }
}

class _SalesListTab extends ConsumerWidget {
  const _SalesListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesListProvider);
    final appUser = ref.watch(appUserProvider).value;
    final isAdmin = appUser?.isAdmin ?? false;
    final canEdit = appUser?.canEdit ?? false;
    final usersAsync = ref.watch(allUsersProvider);
    final users = usersAsync.value ?? [];

    String getUserName(String userId) {
      if (users.isEmpty) return '...';
      try {
        final user = users.firstWhere((u) => u.id == userId);
        return user.businessName;
      } catch (_) {
        return 'Unknown';
      }
    }

    return salesAsync.when(
      data: (sales) {
        if (sales.isEmpty) {
          return const Center(child: Text('No sales found.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sales.length,
          itemBuilder: (context, index) {
            final sale = sales[index];
            final userName = getUserName(sale.userId);
            final isProfit = sale.profit >= 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${sale.customerName} - ${sale.productName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (isAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Total: ${Formatters.formatCurrency(sale.totalAmount)} | Paid: ${Formatters.formatCurrency(sale.paidAmount)}${isAdmin ? ' | Cost: ${Formatters.formatCurrency(sale.totalAmount - sale.profit)}' : ''}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Date: ${Formatters.formatDate(sale.date)}',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                        ),
                        if (isAdmin) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (isProfit
                                          ? AppColors.success
                                          : AppColors.error)
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${isProfit ? 'Profit' : 'Loss'}: ${Formatters.formatCurrency(sale.profit.abs())}',
                              style: TextStyle(
                                color: isProfit
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                trailing: canEdit
                    ? IconButton(
                        icon: const Icon(
                          Icons.edit_note_rounded,
                          color: AppColors.primary,
                        ),
                        onPressed: () => _editSale(context, sale),
                      )
                    : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _editSale(BuildContext context, Sale sale) {
    showDialog(
      context: context,
      builder: (_) => EditSaleDialog(sale: sale),
    );
  }
}

class _ExpensesListTab extends ConsumerWidget {
  const _ExpensesListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseListProvider);
    final appUser = ref.watch(appUserProvider).value;
    final isAdmin = appUser?.isAdmin ?? false;
    final canEdit = appUser?.canEdit ?? false;
    final usersAsync = ref.watch(allUsersProvider);
    final users = usersAsync.value ?? [];

    String getUserName(String userId) {
      if (users.isEmpty) return '...';
      try {
        final user = users.firstWhere((u) => u.id == userId);
        return user.businessName;
      } catch (_) {
        return 'Unknown';
      }
    }

    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return const Center(child: Text('No expenses found.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            final userName = getUserName(expense.userId);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        expense.expenseType,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (isAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Amount: ${Formatters.formatCurrency(expense.amount)}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Notes: ${expense.notes}\nDate: ${Formatters.formatDate(expense.date)}',
                      style: TextStyle(color: AppColors.textHint, fontSize: 12),
                    ),
                  ],
                ),
                trailing: canEdit
                    ? IconButton(
                        icon: const Icon(
                          Icons.edit_note_rounded,
                          color: AppColors.primary,
                        ),
                        onPressed: () => _editExpense(context, expense),
                      )
                    : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _editExpense(BuildContext context, AppExpense expense) {
    showDialog(
      context: context,
      builder: (_) => EditExpenseDialog(expense: expense),
    );
  }
}

class _SalariesListTab extends ConsumerWidget {
  const _SalariesListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salaryAsync = ref.watch(salaryListProvider);
    final appUser = ref.watch(appUserProvider).value;
    final isAdmin = appUser?.isAdmin ?? false;
    final canEdit = appUser?.canEdit ?? false;
    final usersAsync = ref.watch(allUsersProvider);
    final users = usersAsync.value ?? [];

    String getUserName(String userId) {
      if (users.isEmpty) return '...';
      try {
        final user = users.firstWhere((u) => u.id == userId);
        return user.businessName;
      } catch (_) {
        return 'Unknown';
      }
    }

    return salaryAsync.when(
      data: (salaries) {
        if (salaries.isEmpty) {
          return const Center(child: Text('No salary payments found.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: salaries.length,
          itemBuilder: (context, index) {
            final salary = salaries[index];
            final userName = getUserName(salary.userId);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        salary.employeeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (isAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Amount Paid: ${Formatters.formatCurrency(salary.totalDeduction)}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Date: ${Formatters.formatDate(salary.date)}',
                      style: TextStyle(color: AppColors.textHint, fontSize: 12),
                    ),
                  ],
                ),
                trailing: canEdit
                    ? IconButton(
                        icon: const Icon(
                          Icons.edit_note_rounded,
                          color: AppColors.primary,
                        ),
                        onPressed: () => _editSalary(context, salary),
                      )
                    : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _editSalary(BuildContext context, SalaryPayment salary) {
    showDialog(
      context: context,
      builder: (_) => EditSalaryDialog(salary: salary),
    );
  }
}
