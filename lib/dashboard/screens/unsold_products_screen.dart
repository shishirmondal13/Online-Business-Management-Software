import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/utils/calculations.dart';
import '../../shared/widgets/app_table.dart';
import '../../mobile_sector/providers/mobile_provider.dart';
import '../../gadget_sector/providers/gadget_provider.dart';

class UnsoldProductsScreen extends ConsumerWidget {
  const UnsoldProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Unsold Inventory'),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(
                icon: const Icon(Icons.smartphone_outlined),
                text: l10n.mobile,
              ),
              Tab(
                icon: const Icon(Icons.headphones_outlined),
                text: l10n.gadget,
              ),
            ],
          ),
        ),
        body: TabBarView(children: [_MobileUnsoldList(), _GadgetUnsoldList()]),
      ),
    );
  }
}

class _MobileUnsoldList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockListAsync = ref.watch(filteredMobileStockProvider('unsold'));
    final l10n = AppLocalizations.of(context)!;

    return stockListAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return Center(child: Text(l10n.noData));
        }

        // Calculate totals
        final totalCost = list.fold(
          0.0,
          (sum, item) => sum + item.netPurchasePrice,
        );

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Items: ${list.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Total Value: ${Formatters.formatCurrency(totalCost)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppTable(
                  columns: [
                    AppTableColumn(label: l10n.modelName, flex: 3),
                    AppTableColumn(label: 'IMEI', flex: 3),
                    AppTableColumn(
                      label: l10n.purchasePrice,
                      flex: 2,
                      align: TextAlign.right,
                    ),
                  ],
                  rows: list.map((stock) {
                    return AppTableRow(
                      cells: [
                        Text(
                          stock.modelName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          stock.imeiNumber,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontFamily: 'monospace'),
                        ),
                        Text(
                          Formatters.formatCurrency(stock.netPurchasePrice),
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _GadgetUnsoldList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Filter for gadgets with quantity > 0
    final stockListAsync = ref.watch(gadgetStockListProvider);
    final l10n = AppLocalizations.of(context)!;

    return stockListAsync.when(
      data: (allList) {
        final list = allList.where((item) => item.quantity > 0).toList();

        if (list.isEmpty) {
          return Center(child: Text(l10n.noData));
        }

        // Calculate totals
        final totalCost = list.fold(
          0.0,
          (sum, item) => sum + (item.productCost * item.quantity),
        );
        final totalQty = list.fold(0, (sum, item) => sum + item.quantity);

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Items: $totalQty',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Total Value: ${Formatters.formatCurrency(totalCost)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppTable(
                  columns: [
                    AppTableColumn(label: l10n.productName, flex: 3),
                    AppTableColumn(
                      label: l10n.quantity,
                      flex: 1,
                      align: TextAlign.center,
                    ),
                    AppTableColumn(
                      label: 'Unit Cost',
                      flex: 2,
                      align: TextAlign.right,
                    ),
                    AppTableColumn(
                      label: 'Total Cost',
                      flex: 2,
                      align: TextAlign.right,
                    ),
                  ],
                  rows: list.map((stock) {
                    return AppTableRow(
                      cells: [
                        Text(
                          stock.productName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${stock.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(Formatters.formatCurrency(stock.productCost)),
                        Text(
                          Formatters.formatCurrency(
                            stock.productCost * stock.quantity,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
