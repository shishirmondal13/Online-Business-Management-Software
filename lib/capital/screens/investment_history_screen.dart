import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/utils/calculations.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/investment_provider.dart';
import '../models/investment_transaction.dart';

class InvestmentHistoryScreen extends ConsumerStatefulWidget {
  const InvestmentHistoryScreen({super.key});

  @override
  ConsumerState<InvestmentHistoryScreen> createState() =>
      _InvestmentHistoryScreenState();
}

class _InvestmentHistoryScreenState
    extends ConsumerState<InvestmentHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final history = ref.watch(investmentHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Investment History')),
      body: history.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Text(
                'No investment history found',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final isAdd = transaction.type == 'add';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isAdd
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    child: Icon(
                      isAdd ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isAdd ? AppColors.success : AppColors.error,
                    ),
                  ),
                  title: Text(
                    isAdd ? 'Investment Added' : 'Investment Removed',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Formatters.formatDateTime(transaction.date)),
                      if (transaction.investorName.isNotEmpty)
                        Text(
                          'Investor: ${transaction.investorName}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      if (transaction.note.isNotEmpty)
                        Text(
                          transaction.note,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Formatters.formatCurrency(transaction.amount),
                        style: TextStyle(
                          color: isAdd ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showTransactionDialog(
                          context,
                          transaction: transaction,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showTransactionDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              'Add Investment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTransactionDialog(
    BuildContext context, {
    InvestmentTransaction? transaction,
  }) async {
    final isEditing = transaction != null;
    final amountController = TextEditingController(
      text: isEditing ? transaction.amount.toString() : '',
    );
    final noteController = TextEditingController(
      text: isEditing ? transaction.note : '',
    );
    final investorNameController = TextEditingController(
      text: isEditing ? transaction.investorName : '',
    );
    // Only Add investments allowed.

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Investment' : 'Manage Investment'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Removed "Add/Remove" radio buttons to prevent negative investments.
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '৳ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: investorNameController,
                    decoration: const InputDecoration(
                      labelText: 'Investor Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text) ?? 0;
                  if (amount > 0) {
                    final userId = ref.read(currentUserIdProvider);
                    if (userId != null) {
                      if (isEditing) {
                        await ref
                            .read(investmentServiceProvider)
                            .updateTransaction(
                              oldTransaction: transaction,
                              newAmount: amount,
                              newType: 'add',
                              newNote: noteController.text.trim(),
                              newInvestorName: investorNameController.text
                                  .trim(),
                            );
                      } else {
                        await ref
                            .read(investmentServiceProvider)
                            .addTransaction(
                              userId: userId,
                              amount: amount,
                              type: 'add',
                              note: noteController.text.trim(),
                              investorName: investorNameController.text.trim(),
                            );
                      }
                      if (context.mounted) Navigator.pop(ctx);
                    }
                  }
                },
                child: Text(isEditing ? 'Update' : 'Add'),
              ),
            ],
          );
        },
      ),
    );
  }
}
