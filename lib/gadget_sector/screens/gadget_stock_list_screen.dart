import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../shared/l10n/app_localizations.dart';

import '../../shared/constants/app_colors.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/app_table.dart';
import '../../shared/utils/calculations.dart';

import '../providers/gadget_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'add_edit_gadget_screen.dart';

/// Gadget stock list screen with table view
class GadgetStockListScreen extends ConsumerStatefulWidget {
  const GadgetStockListScreen({super.key});

  @override
  ConsumerState<GadgetStockListScreen> createState() =>
      _GadgetStockListScreenState();
}

class _GadgetStockListScreenState extends ConsumerState<GadgetStockListScreen> {
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
        ? ref.watch(searchGadgetStockProvider(_searchController.text))
        : _statusFilter != null
        ? ref.watch(filteredGadgetStockProvider(_statusFilter))
        : ref.watch(gadgetStockListProvider);
    final appUser = ref.watch(appUserProvider).value;
    final canEdit = appUser?.canEdit ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.gadgetStock),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.invalidate(gadgetStockListProvider);
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
              PopupMenuItem(value: 'in_stock', child: Text(l10n.inStock)),
              PopupMenuItem(value: 'low_stock', child: Text(l10n.lowStock)),
              PopupMenuItem(
                value: 'out_of_stock',
                child: Text(l10n.outOfStock),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          ref.invalidate(gadgetStockListProvider);
        },
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppSearchField(
                controller: _searchController,
                hint: 'Search by Product Code or Name...',
                onChanged: (value) => setState(() {}),
                onClear: () => setState(() {}),
              ),
            ),

            // Filter Chips
            if (_statusFilter != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Chip(
                      label: Text(_getStatusLabel(_statusFilter!, l10n)),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => setState(() => _statusFilter = null),
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
                                  Icons.headphones_outlined,
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
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const AddEditGadgetScreen(),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add),
                                    label: Text(l10n.addGadgetStock),
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
                        AppTableColumn(label: l10n.productName, flex: 2),
                        AppTableColumn(
                          label: l10n.quantity,
                          flex: 1,
                          align: TextAlign.center,
                        ),
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
                          label: l10n.stockStatus,
                          flex: 3,
                          align: TextAlign.center,
                        ),
                      ],
                      rows: list.map((stock) {
                        final isSoldOut = stock.stockStatus == 'out_of_stock';
                        return AppTableRow(
                          onTap: canEdit
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddEditGadgetScreen(
                                        gadgetStock: stock,
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
                                  stock.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  stock.productCode,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontFamily: 'monospace',
                                      ),
                                ),
                              ],
                            ),
                            Text(
                              '${stock.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              Formatters.formatCurrency(stock.productCost),
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
                              isSoldOut
                                  ? Formatters.formatCurrency(stock.profit)
                                  : '-',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSoldOut
                                    ? (stock.profit >= 0
                                          ? AppColors.success
                                          : AppColors.error)
                                    : AppColors.textHint,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildStatusBadge(stock.stockStatus, l10n),
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
                                          builder: (_) => AddEditGadgetScreen(
                                            gadgetStock: stock,
                                          ),
                                        ),
                                      );
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
                                  ref.invalidate(gadgetStockListProvider),
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
                    builder: (_) => const AddEditGadgetScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  String _getStatusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'in_stock':
        return l10n.inStock;
      case 'low_stock':
        return l10n.lowStock;
      case 'out_of_stock':
        return l10n.outOfStock;
      default:
        return status;
    }
  }

  Widget _buildStatusBadge(String status, AppLocalizations l10n) {
    Color color;
    String label;
    switch (status) {
      case 'in_stock':
        color = AppColors.inStock;
        label = l10n.inStock;
        break;
      case 'low_stock':
        color = AppColors.lowStock;
        label = l10n.lowStock;
        break;
      case 'out_of_stock':
        color = AppColors.outOfStock;
        label = l10n.outOfStock;
        break;
      default:
        color = AppColors.textHint;
        label = status;
    }

    return AppStatusPill(label: label, color: color);
  }
}
