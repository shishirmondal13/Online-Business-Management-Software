import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../shared/l10n/app_localizations.dart';

import '../../shared/constants/app_colors.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/app_table.dart';
import '../../shared/utils/calculations.dart';

import '../providers/mobile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'add_edit_mobile_screen.dart';
import '../../returns/screens/damage_product_dialog.dart';
import '../../returns/screens/damage_history_screen.dart';

/// Mobile stock list screen with table view
class MobileStockListScreen extends ConsumerStatefulWidget {
  const MobileStockListScreen({super.key});

  @override
  ConsumerState<MobileStockListScreen> createState() =>
      _MobileStockListScreenState();
}

class _MobileStockListScreenState extends ConsumerState<MobileStockListScreen> {
  final _searchController = TextEditingController();
  String? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stockList = _searchController.text.isNotEmpty
        ? ref.watch(searchMobileStockProvider(_searchController.text))
        : _statusFilter != null
        ? ref.watch(filteredMobileStockProvider(_statusFilter))
        : ref.watch(mobileStockListProvider);
    final appUser = ref.watch(appUserProvider).value;
    final canEdit = appUser?.canEdit ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.mobileStock),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Damage History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DamageHistoryScreen(initialSector: 'mobile'),
                ),
              );
            },
          ),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.report_problem_outlined),
              tooltip: 'Record Damaged Mobile',
              onPressed: () async {
                final changed = await showDialog<bool>(
                  context: context,
                  builder: (_) => const DamageProductDialog(productType: 'mobile'),
                );
                if (changed == true) {
                  ref.invalidate(mobileStockListProvider);
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.invalidate(mobileStockListProvider);
            },
          ),
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _statusFilter = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: null, child: Text(l10n.all)),
              PopupMenuItem(value: 'unsold', child: Text(l10n.unsold)),
              PopupMenuItem(value: 'sold', child: Text(l10n.sold)),
              const PopupMenuItem(value: 'damaged', child: Text('Damaged')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          ref.invalidate(mobileStockListProvider);
        },
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppSearchField(
                controller: _searchController,
                hint: 'Search by IMEI or Model...',
                onChanged: (value) {
                  setState(() {});
                },
                onClear: () {
                  setState(() {});
                },
              ),
            ),

            // Filter Chips
            if (_statusFilter != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Chip(
                      label: Text(
                        _statusFilter == 'sold'
                            ? l10n.sold
                            : _statusFilter == 'damaged'
                            ? 'Damaged'
                            : l10n.unsold,
                      ),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _statusFilter = null;
                        });
                      },
                    ),
                  ],
                ),
              ),

            // Stock List
            Expanded(
              child: stockList.when(
                data: (list) {
                  if (list.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.smartphone_outlined,
                                  size: 64,
                                  color: AppColors.textHint,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.noData,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 24),
                                if (canEdit)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const AddEditMobileScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add),
                                    label: Text(l10n.addMobileStock),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: AppTable(
                      columns: [
                        AppTableColumn(label: l10n.modelName, flex: 2),
                        AppTableColumn(label: l10n.imeiNumber, flex: 2),
                        AppTableColumn(
                          label: l10n.productCost,
                          flex: 2,
                          align: TextAlign.right,
                        ),
                        AppTableColumn(
                          label: l10n.sellingPrice,
                          flex: 2,
                          align: TextAlign.right,
                        ),
                        AppTableColumn(
                          label: 'Profit/Loss',
                          flex: 2,
                          align: TextAlign.right,
                        ),
                        AppTableColumn(
                          label: l10n.status,
                          flex: 3,
                          align: TextAlign.center,
                        ),
                      ],
                      rows: list.map((stock) {
                        return AppTableRow(
                          onTap: canEdit
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddEditMobileScreen(
                                        mobileStock: stock,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          cells: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  stock.modelName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (stock.isReturned || stock.returnCount > 0) ...[
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.warning.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.assignment_return_outlined,
                                          size: 11,
                                          color: AppColors.warning,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          stock.returnLabel,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.warning,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                ],
                                Text(
                                  Formatters.formatDate(stock.date),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                            Text(
                              stock.imeiNumber,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                            Text(
                              Formatters.formatCurrency(stock.netPurchasePrice),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              Formatters.formatCurrency(stock.sellingPrice),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              stock.isSold
                                  ? Formatters.formatCurrency(stock.profit)
                                  : '-',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: stock.isSold
                                    ? (stock.profit >= 0
                                          ? AppColors.success
                                          : AppColors.error)
                                    : AppColors.textHint,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppStatusPill(
                                  label: stock.isDamaged
                                      ? 'Damaged'
                                      : stock.isSold
                                      ? l10n.sold
                                      : l10n.unsold,
                                  color: stock.isDamaged
                                      ? AppColors.error
                                      : stock.isSold
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                                if (canEdit) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 16),
                                    color: AppColors.primary,
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddEditMobileScreen(
                                            mobileStock: stock,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  if (stock.isUnsold)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.report_problem_outlined,
                                        size: 16,
                                      ),
                                      color: AppColors.error,
                                      tooltip: 'Mark damaged',
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                      onPressed: () async {
                                        final changed = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => DamageProductDialog(
                                            productType: 'mobile',
                                            productId: stock.id,
                                            productName: stock.modelName,
                                            identifier: stock.imeiNumber,
                                            unitCost: stock.netPurchasePrice,
                                            maxQuantity: 1,
                                          ),
                                        );
                                        if (changed == true) {
                                          ref.invalidate(
                                            mobileStockListProvider,
                                          );
                                        }
                                      },
                                    ),
                                ],
                              ],
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 16),
                            Text(error.toString()),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () =>
                                  ref.invalidate(mobileStockListProvider),
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddEditMobileScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
