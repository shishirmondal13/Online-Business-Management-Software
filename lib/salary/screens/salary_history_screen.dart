import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/utils/calculations.dart';
import '../providers/salary_provider.dart';
import 'salary_payment_screen.dart';

class SalaryHistoryScreen extends ConsumerWidget {
  const SalaryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salaryList = ref.watch(salaryListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Salary History')),
      body: salaryList.when(
        data: (payments) {
          if (payments.isEmpty) {
            return const Center(child: Text('No salary payments found'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha:0.1),
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                  title: Text(
                    payment.employeeName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(Formatters.formatDate(payment.date)),
                  trailing: Text(
                    Formatters.formatCurrency(payment.totalDeduction),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.error,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow('Salary Amount', payment.amount),
                          if (payment.bonus > 0)
                            _buildDetailRow('Bonus', payment.bonus),
                          if (payment.duePaid > 0)
                            _buildDetailRow('Due Paid', payment.duePaid),
                          if (payment.advance > 0)
                            _buildDetailRow('Advance Given', payment.advance),
                          if (payment.deductions > 0)
                            _buildDetailRow('Deductions', payment.deductions),
                          if (payment.notes != null &&
                              payment.notes!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Notes: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(child: Text(payment.notes!)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
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
                  color: AppColors.primary.withValues(alpha:0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SalaryPaymentScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.payments_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'PAY SALARY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            Formatters.formatCurrency(amount),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
