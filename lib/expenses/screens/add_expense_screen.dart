import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String initialExpenseType;

  const AddExpenseScreen({super.key, required this.initialExpenseType});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late String _expenseType;
  DateTime _date = DateTime.now();
  bool _isLoading = false;

  final List<String> _expenseTypes = ['Office rent', 'Shop rent', 'Extra cost'];

  @override
  void initState() {
    super.initState();
    _expenseType = widget.initialExpenseType;
    if (!_expenseTypes.contains(_expenseType)) {
      _expenseType = _expenseTypes.first;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Add $_expenseType')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Expense Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _expenseType,
                decoration: const InputDecoration(
                  labelText: 'Expense Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _expenseTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _expenseType = val);
                  }
                },
              ),
              const SizedBox(height: 24),
              AppCurrencyField(controller: _amountController, label: 'Amount'),
              const SizedBox(height: 24),
              AppDateField(
                value: _date,
                label: 'Date',
                onChanged: (val) => setState(() => _date = val),
              ),
              const SizedBox(height: 24),
              AppTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                prefixIcon: Icons.notes,
                maxLines: 3,
              ),
              const SizedBox(height: 48),
              AppButton(
                text: 'Save Expense',
                isLoading: _isLoading,
                icon: Icons.save_outlined,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.tryParse(_amountController.text) ?? 0;
      final expense = AppExpense.create(
        userId: userId,
        expenseType: _expenseType,
        amount: amount,
        date: _date,
        notes: _notesController.text.trim(),
      );

      await ref.read(expenseServiceProvider).addExpense(expense);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
