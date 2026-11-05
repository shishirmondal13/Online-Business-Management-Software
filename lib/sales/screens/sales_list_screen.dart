import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/services/receipt_service.dart';
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
  String _selectedStatusFilter = 'all';

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
      body: salesList.when(
        data: (list) {
          // Status counts
          final totalAll = list.length;
          final totalPaid = list.where((s) => s.paymentStatus == 'paid').length;
          final totalPartial = list.where((s) => s.paymentStatus == 'partial').length;
          final totalUnpaid = list.where((s) => s.paymentStatus == 'unpaid').length;

          // Filter by status first
          final statusFiltered = _selectedStatusFilter == 'all'
              ? list
              : list.where((s) => s.paymentStatus == _selectedStatusFilter).toList();

          // Filter by search query
          final filteredList = _searchController.text.isEmpty
              ? statusFiltered
              : statusFiltered.where((sale) {
                  final query = _searchController.text.toLowerCase();
                  return sale.customerName.toLowerCase().contains(query) ||
                      sale.productName.toLowerCase().contains(query);
                }).toList();

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: AppSearchField(
                  controller: _searchController,
                  hint: 'Search sales...',
                  onChanged: (value) => setState(() {}),
                  onClear: () => setState(() {}),
                ),
              ),

              // Status Filter Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All Sales', totalAll, Colors.blueGrey),
                    const SizedBox(width: 8),
                    _buildFilterChip('paid', l10n.paid, totalPaid, AppColors.paid),
                    const SizedBox(width: 8),
                    _buildFilterChip('partial', l10n.partialPaid, totalPartial, AppColors.partialPaid),
                    const SizedBox(width: 8),
                    _buildFilterChip('unpaid', l10n.unpaid, totalUnpaid, AppColors.unpaid),
                  ],
                ),
              ),

              // Detailed Amount Breakdown Bar (when Partial Paid or Unpaid is selected)
              if (_selectedStatusFilter == 'partial') ...[
                Builder(builder: (context) {
                  final partialSales = list.where((s) => s.paymentStatus == 'partial').toList();
                  final totalBill = partialSales.fold<double>(0, (acc, s) => acc + s.totalAmount);
                  final totalPaidAmt = partialSales.fold<double>(0, (acc, s) => acc + s.paidAmount);
                  final totalDueAmt = partialSales.fold<double>(0, (acc, s) => acc + s.dueAmount);

                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.partialPaid.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.partialPaid.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: AppColors.partialPaid),
                            const SizedBox(width: 6),
                            Text(
                              'Partial Paid Details ($totalPartial Sales)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.partialPaid,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryMetric(
                                'Total Invoiced',
                                Formatters.formatCurrency(totalBill),
                                AppColors.textPrimary,
                              ),
                            ),
                            Expanded(
                              child: _buildSummaryMetric(
                                'Paid So Far',
                                Formatters.formatCurrency(totalPaidAmt),
                                AppColors.paid,
                              ),
                            ),
                            Expanded(
                              child: _buildSummaryMetric(
                                'Remaining Due',
                                Formatters.formatCurrency(totalDueAmt),
                                AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ] else if (_selectedStatusFilter == 'unpaid') ...[
                Builder(builder: (context) {
                  final unpaidSales = list.where((s) => s.paymentStatus == 'unpaid').toList();
                  final totalBill = unpaidSales.fold<double>(0, (acc, s) => acc + s.totalAmount);
                  final totalDueAmt = unpaidSales.fold<double>(0, (acc, s) => acc + s.dueAmount);

                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.unpaid.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.unpaid.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryMetric('Unpaid Invoices', '$totalUnpaid', AppColors.unpaid),
                        _buildSummaryMetric('Total Due Amount', Formatters.formatCurrency(totalDueAmt > 0 ? totalDueAmt : totalBill), AppColors.error),
                      ],
                    ),
                  );
                }),
              ],

              Expanded(
                child: filteredList.isEmpty
                    ? Center(
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
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
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
                      )
                    : Padding(
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
                                _showSaleAmountDetailsDialog(sale, canEdit);
                              },
                              cells: [
                                Text(
                                  Formatters.formatDate(sale.date),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
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
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
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
                                    ReceiptService()
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
                                              builder: (_) => ReturnSaleDialog(sale: sale),
                                            );
                                            if (changed == true && context.mounted) {
                                              ref.invalidate(salesListProvider);
                                              ref.invalidate(customersDueListProvider);
                                            }
                                          },
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
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

  Widget _buildFilterChip(
    String filterKey,
    String label,
    int count,
    Color color,
  ) {
    final isSelected = _selectedStatusFilter == filterKey;
    return ChoiceChip(
      selected: isSelected,
      label: Text('$label ($count)'),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      selectedColor: color,
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(
        color: isSelected ? color : color.withValues(alpha: 0.25),
      ),
      onSelected: (_) {
        HapticFeedback.selectionClick();
        setState(() => _selectedStatusFilter = filterKey);
      },
    );
  }

  Widget _buildSummaryMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
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

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        _showSaleAmountDetailsDialog(sale, canEdit);
      },
      borderRadius: BorderRadius.circular(16),
      child: Tooltip(
        message: sale.paymentStatus == 'partial'
            ? 'Partial Paid: Paid ৳${sale.paidAmount.toStringAsFixed(2)} | Due ৳${sale.dueAmount.toStringAsFixed(2)} (Click to view amount details)'
            : (sale.paymentStatus == 'unpaid'
                ? 'Unpaid / Due: ৳${sale.dueAmount.toStringAsFixed(2)} (Click for details)'
                : 'Fully Paid (Click for details)'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppStatusPill(label: label, color: color),
            const SizedBox(width: 4),
            Icon(
              sale.paymentStatus == 'paid'
                  ? Icons.check_circle_outline
                  : (sale.paymentStatus == 'partial'
                      ? Icons.info_outline
                      : Icons.payment),
              size: 14,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSaleAmountDetailsDialog(Sale sale, bool canEdit) async {
    final l10n = AppLocalizations.of(context)!;

    // Fetch payments for this sale from Firestore
    List<Payment> payments = [];
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('saleId', isEqualTo: sale.id)
          .orderBy('date', descending: true)
          .get();
      if (snapshot.docs.isEmpty && sale.customerId.isNotEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection('payments')
            .where('customerId', isEqualTo: sale.customerId)
            .orderBy('date', descending: true)
            .get();
      }
      payments = snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();
    } catch (_) {}

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        final total = sale.totalAmount;
        final paid = sale.paidAmount;
        final due = sale.dueAmount;
        final paidPercent = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;
        final percentStr = (paidPercent * 100).toStringAsFixed(0);

        final isPaid = sale.paymentStatus == 'paid';
        final isPartial = sale.paymentStatus == 'partial';
        final statusColor = isPaid
            ? AppColors.paid
            : (isPartial ? AppColors.partialPaid : AppColors.unpaid);
        final statusText = isPaid
            ? l10n.paid
            : (isPartial ? l10n.partialPaid : l10n.unpaid);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPaid ? Icons.check_circle : (isPartial ? Icons.timelapse : Icons.warning_amber),
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment & Amount Details',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${sale.customerName.isNotEmpty ? sale.customerName : 'Walk-in'} • ${sale.productName}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AppStatusPill(label: statusText, color: statusColor),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3-Card Financial Overview
                  Row(
                    children: [
                      Expanded(
                        child: _buildAmountCard(
                          'Total Bill',
                          Formatters.formatCurrency(total),
                          AppColors.textPrimary,
                          Icons.receipt,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAmountCard(
                          'Paid Amount',
                          Formatters.formatCurrency(paid),
                          AppColors.paid,
                          Icons.check_circle_outline,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAmountCard(
                          'Due Balance',
                          Formatters.formatCurrency(due),
                          due > 0 ? AppColors.error : AppColors.textSecondary,
                          Icons.pending_actions,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Payment Completion',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '$percentStr% Paid',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: paidPercent,
                          minHeight: 8,
                          color: statusColor,
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Payment Breakdown History
                  Text(
                    'Payment Transactions (${payments.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (payments.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              paid > 0
                                  ? 'Initial payment of ৳${paid.toStringAsFixed(2)} collected at checkout.'
                                  : 'No payment recorded yet for this transaction.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...payments.map((p) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('dd MMM yyyy, hh:mm a').format(p.date),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (p.notes.isNotEmpty)
                                    Text(
                                      p.notes,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      p.paymentMethod.toUpperCase(),
                                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '+${Formatters.formatCurrency(p.amount)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.paid,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Close'),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.receipt_long, size: 16),
              label: const Text('Invoice PDF'),
              onPressed: () {
                Navigator.pop(dialogCtx);
                ReceiptService().showInvoiceOptionsDialog(context, sale);
              },
            ),
            if (sale.dueAmount > 0.001 && canEdit)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.payment, size: 16),
                label: const Text('Collect Due'),
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  _showClearDueDialog(sale);
                },
              ),
          ],
        );
      },
    );
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
