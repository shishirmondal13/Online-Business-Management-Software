import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/utils/calculations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../sales/models/sale.dart';
import '../../sales/providers/sales_provider.dart';

class DueDetailsScreen extends ConsumerStatefulWidget {
  final Customer customer;
  const DueDetailsScreen({super.key, required this.customer});

  @override
  ConsumerState<DueDetailsScreen> createState() => _DueDetailsScreenState();
}

class _DueDetailsScreenState extends ConsumerState<DueDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final payments = ref.watch(customerPaymentsProvider(widget.customer.id));
    final customerAsync = ref.watch(singleCustomerProvider(widget.customer.id));
    final currentCustomer = customerAsync.value ?? widget.customer;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(currentCustomer.name)),
      body: Column(
        children: [
          // Summary Card
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildRow(
                  context,
                  l10n.totalDue,
                  Formatters.formatCurrency(currentCustomer.totalDue),
                ),
                _buildRow(
                  context,
                  l10n.paidAmount,
                  Formatters.formatCurrency(currentCustomer.totalPaid),
                  color: AppColors.success,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: AppColors.tableBorder),
                ),
                _buildRow(
                  context,
                  l10n.remainingDue,
                  Formatters.formatCurrency(currentCustomer.remainingDue),
                  color: currentCustomer.remainingDue <= 0.001
                      ? AppColors.success
                      : AppColors.error,
                  isBold: true,
                  isLarge: true,
                ),
              ],
            ),
          ),
          // Payment History
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.paymentHistory,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                if ((ref.watch(appUserProvider).value?.canEdit ?? false) &&
                    currentCustomer.remainingDue > 0.001)
                  TextButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(l10n.addPayment),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _showAddPaymentDialog(currentCustomer);
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: payments.when(
              data: (list) => list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No payments yet',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final payment = list[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.tableBorder),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.payments_outlined,
                                color: AppColors.success,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              Formatters.formatCurrency(payment.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${Formatters.formatDate(payment.date)} • ${payment.paymentMethod.toUpperCase()}',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            trailing: payment.notes.isNotEmpty
                                ? Tooltip(
                                    message: payment.notes,
                                    child: Icon(
                                      Icons.note_outlined,
                                      color: AppColors.textSecondary,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    String label,
    String value, {
    Color? color,
    bool isBold = false,
    bool isLarge = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: isLarge
                ? Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color ?? AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  )
                : Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color ?? AppColors.textPrimary,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddPaymentDialog(Customer currentCustomer) async {
    final l10n = AppLocalizations.of(context)!;
    final amountController = TextEditingController();
    String method = 'cash';
    bool isSaving = false;

    try {
      await showDialog(
        context: context,
        builder: (dialogCtx) => StatefulBuilder(
          builder: (dialogCtx, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(l10n.addPayment),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l10n.remainingDue}:',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      Formatters.formatCurrency(currentCustomer.remainingDue),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Clear Full Due'),
                    onPressed: isSaving
                        ? null
                        : () {
                            setDialogState(() {
                              amountController.text = currentCustomer.remainingDue
                                  .toStringAsFixed(2);
                            });
                          },
                  ),
                ),
                const SizedBox(height: 8),
                AppCurrencyField(
                  controller: amountController,
                  label: l10n.amount,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: method,
                  decoration: InputDecoration(
                    labelText: l10n.paymentMethod,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  items: ['cash', 'bkash', 'nagad', 'bank']
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: isSaving
                      ? null
                      : (v) => setDialogState(() => method = v ?? 'cash'),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.all(20),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        final amount =
                            double.tryParse(amountController.text) ?? 0;
                        if (amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid amount'),
                            ),
                          );
                          return;
                        }
                        setDialogState(() => isSaving = true);
                        try {
                          final userId = ref.read(currentUserIdProvider);
                          if (userId == null) {
                            throw StateError('User not authenticated');
                          }
                          await ref
                              .read(salesServiceProvider)
                              .addPayment(
                                userId: userId,
                                customerId: currentCustomer.id,
                                saleId: '',
                                amount: amount,
                                paymentMethod: method,
                              );
                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Payment recorded and sales updated!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Payment failed: $e')),
                            );
                          }
                        } finally {
                          if (dialogCtx.mounted) {
                            setDialogState(() => isSaving = false);
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.save),
              ),
            ],
          ),
        ),
      );
    } finally {
      amountController.dispose();
    }
  }
}
