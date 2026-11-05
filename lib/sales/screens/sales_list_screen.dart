import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/utils/calculations.dart';
import '../../shared/widgets/app_table.dart';
import '../../shared/widgets/app_text_field.dart';

import '../models/sale.dart';
import '../providers/sales_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'new_sale_screen.dart';
import '../../returns/screens/return_sale_dialog.dart';

class SalesListScreen extends ConsumerStatefulWidget {
  const SalesListScreen({super.key});

  @override
  ConsumerState<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends ConsumerState<SalesListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        ref.read(salesServiceProvider).syncClearedSalesStatus(userId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final salesList = ref.watch(salesListProvider);
    final appUser = ref.watch(appUserProvider).value;
    final canEdit = appUser?.canEdit ?? false;
    final isAdmin = appUser?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.sales)),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppSearchField(
              controller: _searchController,
              hint: 'Search sales...',
              onChanged: (value) => setState(() {}),
              onClear: () => setState(() {}),
            ),
          ),

          Expanded(
            child: salesList.when(
              data: (list) {
                // Filter list based on search
                final filteredList = _searchController.text.isEmpty
                    ? list
                    : list.where((sale) {
                        final query = _searchController.text.toLowerCase();
                        return sale.customerName.toLowerCase().contains(
                              query,
                            ) ||
                            sale.productName.toLowerCase().contains(query);
                      }).toList();

                if (filteredList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.point_of_sale_outlined,
                          size: 64,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noData,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        if (canEdit)
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NewSaleScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.add),
                            label: Text(l10n.newSale),
                          ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: AppTable(
                    columns: [
                      AppTableColumn(label: l10n.date, flex: 2),
                      AppTableColumn(label: l10n.customerName, flex: 3),
                      AppTableColumn(label: l10n.productName, flex: 3),
                      AppTableColumn(
                        label: l10n.totalAmount,
                        flex: 2,
                        align: TextAlign.right,
                      ),
                      if (isAdmin)
                        AppTableColumn(
                          label: 'Profit',
                          flex: 2,
                          align: TextAlign.right,
                        ),
                      AppTableColumn(
                        label: l10n.status,
                        flex: 2,
                        align: TextAlign.center,
                      ),
                      AppTableColumn(
                        label: 'Receipt',
                        flex: 1,
                        align: TextAlign.center,
                      ),
                      if (canEdit)
                        const AppTableColumn(
                          label: 'Return',
                          flex: 1,
                          align: TextAlign.center,
                        ),
                    ],
                    rows: filteredList.map((sale) {
                      return AppTableRow(
                        onTap: () {
                          // Navigate to sale details if needed
                        },
                        cells: [
                          Text(
                            Formatters.formatDate(sale.date),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          Text(
                            sale.customerName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(sale.productName),
                              Text(
                                '${l10n.quantity}: ${sale.quantity}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          Text(
                            Formatters.formatCurrency(sale.totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (isAdmin)
                            Text(
                              Formatters.formatCurrency(sale.profit),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: sale.profit >= 0
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          Center(
                            child: _buildStatusBadge(sale, l10n, canEdit),
                          ),
                          IconButton(
                            icon: const Icon(Icons.receipt_long_outlined),
                            color: AppColors.primary,
                            tooltip: 'Invoice & Download PDF',
                            onPressed: () {
                              ref
                                  .read(receiptServiceProvider)
                                  .showInvoiceOptionsDialog(context, sale);
                            },
                          ),
                          if (canEdit)
                            IconButton(
                              icon: const Icon(
                                Icons.assignment_return_outlined,
                              ),
                              color: AppColors.warning,
                              tooltip: 'Return product',
                              onPressed: sale.returnedQuantity >= sale.quantity
                                  ? null
                                  : () async {
                                      final changed = await showDialog<bool>(
                                        context: context,
                                        builder: (_) =>
                                            ReturnSaleDialog(sale: sale),
                                      );
                                      if (changed == true && context.mounted) {
                                        ref.invalidate(salesListProvider);
                                        ref.invalidate(
                                          customersDueListProvider,
                                        );
                                      }
                                    },
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
            ),
          ),
        ],
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewSaleScreen()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildStatusBadge(
    Sale sale,
    AppLocalizations l10n,
    bool canEdit,
  ) {
    Color color;
    String label;
    switch (sale.paymentStatus) {
      case 'paid':
        color = AppColors.paid;
        label = l10n.paid;
        break;
      case 'partial':
        color = AppColors.partialPaid;
        label = l10n.partialPaid;
        break;
      default:
        color = AppColors.unpaid;
        label = l10n.unpaid;
    }

    if (sale.paymentStatus != 'paid' && canEdit) {
      return InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          _showClearDueDialog(sale);
        },
        borderRadius: BorderRadius.circular(16),
        child: Tooltip(
          message: 'Click to collect due (৳${sale.dueAmount.toStringAsFixed(2)})',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppStatusPill(label: label, color: color),
              const SizedBox(width: 4),
              Icon(Icons.payment, size: 14, color: color),
            ],
          ),
        ),
      );
    }

    return AppStatusPill(label: label, color: color);
  }

  Future<void> _showClearDueDialog(Sale sale) async {
    final l10n = AppLocalizations.of(context)!;
    final initialDue = sale.dueAmount > 0
        ? sale.dueAmount
        : (sale.totalAmount - sale.paidAmount).clamp(0.0, double.infinity);
    final amountController =
        TextEditingController(text: initialDue.toStringAsFixed(2));
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
                Text(
                  '${l10n.customerName}: ${sale.customerName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${l10n.productName}: ${sale.productName}',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l10n.remainingDue}:',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    Text(
                      Formatters.formatCurrency(initialDue),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
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
                              amountController.text =
                                  initialDue.toStringAsFixed(2);
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
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        final amount =
                            double.tryParse(amountController.text) ?? 0;
                        if (amount <= 0) return;
                        setDialogState(() => isSaving = true);
                        try {
                          final userId = ref.read(currentUserIdProvider);
                          if (userId == null) {
                            throw StateError('User not authenticated');
                          }
                          await ref
                              .read(salesServiceProvider)
                              .addPayment(
                                customerId: sale.customerId,
                                amount: amount,
                                userId: userId,
                                saleId: sale.id,
                                paymentMethod: method,
                                notes: 'Payment against ${sale.productName}',
                              );
                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Payment recorded and sale updated to Paid!'),
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
