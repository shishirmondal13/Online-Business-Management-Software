import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/utils/calculations.dart';
import '../../shared/widgets/app_table.dart';
import '../../shared/widgets/app_text_field.dart';

import '../providers/sales_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'new_sale_screen.dart';

class SalesListScreen extends ConsumerStatefulWidget {
  const SalesListScreen({super.key});

  @override
  ConsumerState<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends ConsumerState<SalesListScreen> {
  final _searchController = TextEditingController();

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
                            child: _buildStatusBadge(sale.paymentStatus, l10n),
                          ),
                          IconButton(
                            icon: const Icon(Icons.receipt_long_outlined),
                            color: AppColors.primary,
                            onPressed: () {
                              ref
                                  .read(receiptServiceProvider)
                                  .generateReceipt(sale);
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

  Widget _buildStatusBadge(String status, AppLocalizations l10n) {
    Color color;
    String label;
    switch (status) {
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
    return AppStatusPill(label: label, color: color);
  }
}
