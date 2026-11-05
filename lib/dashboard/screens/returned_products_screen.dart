import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/utils/calculations.dart';
import '../../shared/widgets/app_table.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../mobile_sector/models/mobile_stock.dart';
import '../../mobile_sector/providers/mobile_provider.dart';
import '../../mobile_sector/screens/add_edit_mobile_screen.dart';
import '../../gadget_sector/models/gadget_stock.dart';
import '../../gadget_sector/providers/gadget_provider.dart';
import '../../gadget_sector/screens/add_edit_gadget_screen.dart';
import '../../auth/providers/auth_provider.dart';

/// Returned Products Screen showing returned items in Mobile and Gadget sectors
class ReturnedProductsScreen extends ConsumerStatefulWidget {
  final String? initialSector; // 'mobile' or 'gadget'

  const ReturnedProductsScreen({this.initialSector, super.key});

  @override
  ConsumerState<ReturnedProductsScreen> createState() =>
      _ReturnedProductsScreenState();
}

class _ReturnedProductsScreenState
    extends ConsumerState<ReturnedProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialSector == 'gadget' ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final returnedMobiles = ref.watch(returnedMobileStockProvider);
    final returnedGadgets = ref.watch(returnedGadgetStockProvider);

    final mobileCount = returnedMobiles.value?.length ?? 0;
    final gadgetCount = returnedGadgets.value?.fold<int>(
          0,
          (sum, g) => sum + (g.returnedQuantity > 0 ? g.returnedQuantity : 1),
        ) ??
        0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Returned Products'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.warning,
          labelColor: AppColors.warning,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(
              icon: const Icon(Icons.smartphone_outlined),
              text: '${l10n.mobile} ($mobileCount)',
            ),
            Tab(
              icon: const Icon(Icons.headphones_outlined),
              text: '${l10n.gadget} ($gadgetCount)',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.invalidate(mobileStockListProvider);
              ref.invalidate(gadgetStockListProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AppSearchField(
              controller: _searchController,
              hint: 'Search returned items by name, code or IMEI...',
              onChanged: (_) => setState(() {}),
              onClear: () => setState(() {}),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MobileReturnedList(searchQuery: _searchController.text.trim()),
                _GadgetReturnedList(searchQuery: _searchController.text.trim()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileReturnedList extends ConsumerWidget {
  final String searchQuery;

  const _MobileReturnedList({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final returnedMobilesAsync = ref.watch(returnedMobileStockProvider);
    final l10n = AppLocalizations.of(context)!;
    final appUser = ref.watch(appUserProvider).value;
    final canEdit = appUser?.canEdit ?? false;

    return returnedMobilesAsync.when(
      data: (list) {
        var filteredList = list;
        if (searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          filteredList = filteredList.where((item) {
            return item.modelName.toLowerCase().contains(query) ||
                item.imeiNumber.toLowerCase().contains(query) ||
                item.returnReason.toLowerCase().contains(query);
          }).toList();
        }

        if (filteredList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.assignment_return_outlined,
                  size: 64,
                  color: AppColors.textHint,
                ),
                const SizedBox(height: 16),
                Text(
                  searchQuery.isEmpty
                      ? 'No returned mobile phones'
                      : 'No matching returned phones found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          );
        }

        final totalValue = filteredList.fold<double>(
          0.0,
          (sum, item) => sum + item.netPurchasePrice,
        );

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.warning.withValues(alpha: 0.08),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Total Returned Mobiles: ${filteredList.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Cost Value: ${Formatters.formatCurrency(totalValue)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
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
                    AppTableColumn(label: 'IMEI', flex: 2),
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
                      label: 'Return Details',
                      flex: 3,
                      align: TextAlign.left,
                    ),
                    AppTableColumn(
                      label: l10n.status,
                      flex: 2,
                      align: TextAlign.center,
                    ),
                  ],
                  rows: filteredList.map((stock) {
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
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.warning.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                stock.returnLabel,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning,
                                ),
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
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          Formatters.formatCurrency(stock.sellingPrice),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              stock.returnReason.isNotEmpty
                                  ? stock.returnReason
                                  : 'Customer Return',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (stock.returnedAt != null)
                              Text(
                                Formatters.formatDate(stock.returnedAt!),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                              ),
                          ],
                        ),
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
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}

class _GadgetReturnedList extends ConsumerWidget {
  final String searchQuery;

  const _GadgetReturnedList({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final returnedGadgetsAsync = ref.watch(returnedGadgetStockProvider);
    final l10n = AppLocalizations.of(context)!;
    final appUser = ref.watch(appUserProvider).value;
    final canEdit = appUser?.canEdit ?? false;

    return returnedGadgetsAsync.when(
      data: (list) {
        var filteredList = list;
        if (searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          filteredList = filteredList.where((item) {
            return item.productName.toLowerCase().contains(query) ||
                item.productCode.toLowerCase().contains(query) ||
                item.returnReason.toLowerCase().contains(query);
          }).toList();
        }

        if (filteredList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.assignment_return_outlined,
                  size: 64,
                  color: AppColors.textHint,
                ),
                const SizedBox(height: 16),
                Text(
                  searchQuery.isEmpty
                      ? 'No returned gadget products'
                      : 'No matching returned gadgets found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          );
        }

        final totalReturnedUnits = filteredList.fold<int>(
          0,
          (sum, item) =>
              sum + (item.returnedQuantity > 0 ? item.returnedQuantity : 1),
        );
        final totalValue = filteredList.fold<double>(
          0.0,
          (sum, item) =>
              sum +
              (item.productCost *
                  (item.returnedQuantity > 0 ? item.returnedQuantity : 1)),
        );

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.warning.withValues(alpha: 0.08),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Total Returned Units: $totalReturnedUnits pcs',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Cost Value: ${Formatters.formatCurrency(totalValue)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
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
                    AppTableColumn(label: 'Code', flex: 2),
                    AppTableColumn(
                      label: 'Returned Qty',
                      flex: 2,
                      align: TextAlign.center,
                    ),
                    AppTableColumn(
                      label: 'In Stock',
                      flex: 1,
                      align: TextAlign.center,
                    ),
                    AppTableColumn(
                      label: l10n.productCost,
                      flex: 2,
                      align: TextAlign.right,
                    ),
                    AppTableColumn(
                      label: 'Return Details',
                      flex: 3,
                      align: TextAlign.left,
                    ),
                  ],
                  rows: filteredList.map((stock) {
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
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.warning.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                stock.returnLabel,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          stock.productCode,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                        Text(
                          '${stock.returnedQuantity} pcs',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                        Text(
                          '${stock.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          Formatters.formatCurrency(stock.productCost),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              stock.returnReason.isNotEmpty
                                  ? stock.returnReason
                                  : 'Customer Return',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (stock.returnedAt != null)
                              Text(
                                Formatters.formatDate(stock.returnedAt!),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                              ),
                          ],
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
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}
