import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/utils/calculations.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/salary_payment.dart';
import '../models/employee.dart';
import '../providers/salary_provider.dart';
import '../providers/employee_provider.dart';

class SalaryPaymentScreen extends ConsumerStatefulWidget {
  const SalaryPaymentScreen({super.key});

  @override
  ConsumerState<SalaryPaymentScreen> createState() =>
      _SalaryPaymentScreenState();
}

class _SalaryPaymentScreenState extends ConsumerState<SalaryPaymentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _amountController = TextEditingController();
  final _bonusController = TextEditingController();
  final _duePaidController = TextEditingController();
  final _advanceController = TextEditingController();
  final _deductionsController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  Employee? _selectedEmployee;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _bonusController.dispose();
    _duePaidController.dispose();
    _advanceController.dispose();
    _deductionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onEmployeeSelected(Employee? employee) {
    setState(() {
      _selectedEmployee = employee;
      if (employee != null) {
        _amountController.text = employee.salary.toString();
      } else {
        _amountController.clear();
      }
    });
  }

  double get _totalPayable {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final bonus = double.tryParse(_bonusController.text) ?? 0;
    final due = double.tryParse(_duePaidController.text) ?? 0;
    final advance = double.tryParse(_advanceController.text) ?? 0;
    final deductions = double.tryParse(_deductionsController.text) ?? 0;

    // Total Cash Out = (Salary + Bonus + Due Paid + Advance) - Deductions
    // Note: Deductions reduce the payout.
    return (amount + bonus + due + advance) - deductions;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an employee')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('User not logged in');

      final payment = SalaryPayment(
        id: const Uuid().v4(),
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        employeeName: _selectedEmployee!.name,
        amount: double.tryParse(_amountController.text) ?? 0,
        bonus: double.tryParse(_bonusController.text) ?? 0,
        duePaid: double.tryParse(_duePaidController.text) ?? 0,
        advance: double.tryParse(_advanceController.text) ?? 0,
        deductions: double.tryParse(_deductionsController.text) ?? 0,
        date: _selectedDate,
        notes: _notesController.text.trim(),
      );

      await ref.read(salaryServiceProvider).addSalaryPayment(payment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salary payment recorded successfully')),
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

  @override
  Widget build(BuildContext context) {
    final activeEmployees = ref.watch(activeEmployeeListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pay Salary')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Employee Selection
              _buildSectionTitle('Employee Details'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      activeEmployees.when(
                        data: (employees) => DropdownButtonFormField<Employee>(
                          initialValue: _selectedEmployee,
                          decoration: const InputDecoration(
                            labelText: 'Select Employee',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          items: employees.map((e) {
                            return DropdownMenuItem(
                              value: e,
                              child: Text('${e.name} (${e.designation})'),
                            );
                          }).toList(),
                          onChanged: _onEmployeeSelected,
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Error loading employees: $e'),
                      ),
                      const SizedBox(height: 16),
                      AppDateField(
                        value: _selectedDate,
                        label: 'Payment Date',
                        onChanged: (d) => setState(() => _selectedDate = d),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Earnings Section
              _buildSectionTitle('Earnings & Additions'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      AppCurrencyField(
                        controller: _amountController,
                        label: 'Base Salary',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppCurrencyField(
                              controller: _bonusController,
                              label: 'Bonus',
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppCurrencyField(
                              controller: _duePaidController,
                              label: 'Due Paid',
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppCurrencyField(
                        controller: _advanceController,
                        label: 'New Advance Given',
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 3. Deductions Section
              _buildSectionTitle('Deductions'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AppCurrencyField(
                    controller: _deductionsController,
                    label: 'Deductions (Fines/Absence)',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 4. Notes
              AppTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // 5. Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.1),
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Base Salary', _amountController.text),
                    _buildSummaryRow(
                      'Bonus',
                      _bonusController.text,
                      isAddition: true,
                    ),
                    _buildSummaryRow(
                      'Due Paid',
                      _duePaidController.text,
                      isAddition: true,
                    ),
                    _buildSummaryRow(
                      'Advance Given',
                      _advanceController.text,
                      isAddition: true,
                    ),
                    _buildSummaryRow(
                      'Deductions',
                      _deductionsController.text,
                      isDeduction: true,
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Payable:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(_totalPayable),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF1A5276)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _handleSubmit,
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'CONFIRM PAYMENT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isAddition = false,
    bool isDeduction = false,
  }) {
    final amount = double.tryParse(value) ?? 0;
    if (amount == 0) return const SizedBox.shrink();

    Color color = AppColors.textPrimary;
    String prefix = '';

    if (isAddition) {
      color = AppColors.success;
      prefix = '+ ';
    } else if (isDeduction) {
      color = AppColors.error;
      prefix = '- ';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            '$prefix${Formatters.formatCurrency(amount)}',
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
