import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/utils/calculations.dart';
import '../../shared/widgets/app_table.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mobile_sector/providers/mobile_provider.dart';
import '../../gadget_sector/providers/gadget_provider.dart';
import '../providers/return_provider.dart';
import 'damage_product_dialog.dart';

/// Damaged products history screen
class DamageHistoryScreen extends ConsumerStatefulWidget {
  final String? initialSector; // 'mobile', 'gadget', or null for all

  const DamageHistoryScreen({this.initialSector, super.key});

  @override
  ConsumerState<DamageHistoryScreen> createState() =>
      _DamageHistoryScreenState();
}

class _DamageHistoryScreenState extends ConsumerState<DamageHistoryScreen> {
  final _searchController = TextEditingController();
  late String _sectorFilter; // 'all', 'mobile', 'gadget'

  @override
  void initState() {
    super.initState();
    _sectorFilter = widget.initialSector ?? 'all';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(returnServiceProvider).syncMissingDamageEvents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final damageEventsAsync = ref.watch(damageEventListProvider);
    final appUser = ref.watch(appUserProvider).value;
    final canEdit = appUser?.canEdit ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Damaged Products History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () async {
              HapticFeedback.mediumImpact();
              await ref.read(returnServiceProvider).syncMissingDamageEvents();
              ref.invalidate(rawDamageEventsProvider);
              ref.invalidate(mobileStockListProvider);
              ref.invalidate(gadgetStockListProvider);
              ref.invalidate(returnListProvider);
              ref.invalidate(damageEventListProvider);
            },
          ),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Record Damaged Product',
              onPressed: () => _openAddDamageDialog(context),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          await ref.read(returnServiceProvider).syncMissingDamageEvents();
          ref.invalidate(rawDamageEventsProvider);
          ref.invalidate(mobileStockListProvider);
          ref.invalidate(gadgetStockListProvider);
          ref.invalidate(returnListProvider);
          ref.invalidate(damageEventListProvider);
        },
        child: damageEventsAsync.when(
          data: (allEvents) {
            // Apply Sector Filter
            var filteredList = allEvents;
            if (_sectorFilter == 'mobile') {
              filteredList = filteredList.where((e) => e.isMobile).toList();
            } else if (_sectorFilter == 'gadget') {
              filteredList = filteredList.where((e) => e.isGadget).toList();
            }

            // Apply Search Query Filter
            final query = _searchController.text.trim().toLowerCase();
            if (query.isNotEmpty) {
              filteredList = filteredList.where((e) {
                return e.productName.toLowerCase().contains(query) ||
                    e.identifier.toLowerCase().contains(query) ||
                    e.reason.toLowerCase().contains(query);
              }).toList();
            }

            // Summary Metrics for the active filter
            final totalDamagedUnits = filteredList.fold<int>(
              0,
              (sum, item) => sum + item.quantity,
            );
            final totalLossAmount = filteredList.fold<double>(
              0.0,
              (sum, item) => sum + item.damageValue,
            );

            final totalAllUnits = allEvents.fold<int>(
              0,
              (sum, item) => sum + item.quantity,
            );

            final mobileCount = allEvents
                .where((e) => e.isMobile)
                .fold<int>(0, (sum, item) => sum + item.quantity);
            final gadgetCount = allEvents
                .where((e) => e.isGadget)
                .fold<int>(0, (sum, item) => sum + item.quantity);

            return Column(
              children: [
                // KPI Metric Summary Banner
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.tableBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Damaged Items',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalDamagedUnits units',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.divider,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Damage Loss',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.formatCurrency(totalLossAmount),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.error,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Sector Segmented Buttons & Search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                              value: 'all',
                              label: Text('All ($totalAllUnits)'),
                              icon: const Icon(Icons.inventory_2_outlined, size: 16),
                            ),
                            ButtonSegment(
                              value: 'mobile',
                              label: Text('Mobiles ($mobileCount)'),
                              icon: const Icon(Icons.smartphone_rounded, size: 16),
                            ),
                            ButtonSegment(
                              value: 'gadget',
                              label: Text('Gadgets ($gadgetCount)'),
                              icon: const Icon(Icons.headphones_rounded, size: 16),
                            ),
                          ],
                          selected: {_sectorFilter},
                          onSelectionChanged: (set) {
                            HapticFeedback.selectionClick();
                            setState(() => _sectorFilter = set.first);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppSearchField(
                        controller: _searchController,
                        hint: 'Search by model, IMEI, code, or reason...',
                        onChanged: (_) => setState(() {}),
                        onClear: () => setState(() {}),
                      ),
                    ],
                  ),
                ),

                // Damage History Table / List
                Expanded(
                  child: filteredList.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.45,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 48,
                                        color: AppColors.success,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      query.isNotEmpty
                                          ? 'No matching damaged items found'
                                          : 'No damaged products recorded',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Damaged products deducted from inventory will appear here.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppColors.textHint),
                                    ),
                                    if (canEdit) ...[
                                      const SizedBox(height: 20),
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            _openAddDamageDialog(context),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Record Damage'),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: AppTable(
                            columns: const [
                              AppTableColumn(label: 'Product', flex: 3),
                              AppTableColumn(label: 'Identifier', flex: 2),
                              AppTableColumn(
                                label: 'Qty',
                                flex: 1,
                                align: TextAlign.center,
                              ),
                              AppTableColumn(
                                label: 'Loss Value',
                                flex: 2,
                                align: TextAlign.right,
                              ),
                              AppTableColumn(label: 'Reason & Date', flex: 3),
                            ],
                            rows: filteredList.map((event) {
                              final isMob = event.isMobile;
                              return AppTableRow(
                                cells: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            isMob
                                                ? Icons.smartphone_rounded
                                                : Icons.headphones_rounded,
                                            size: 16,
                                            color: isMob
                                                ? AppColors.mobileSector
                                                : AppColors.gadgetSector,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              event.productName.isNotEmpty
                                                  ? event.productName
                                                  : (isMob ? 'Mobile' : 'Gadget'),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        isMob ? 'Mobile Sector' : 'Gadget Sector',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: isMob
                                                  ? AppColors.mobileSector
                                                  : AppColors.gadgetSector,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    event.identifier.isNotEmpty
                                        ? event.identifier
                                        : '-',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${event.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        Formatters.formatCurrency(
                                          event.damageValue,
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.error,
                                        ),
                                      ),
                                      if (event.quantity > 1)
                                        Text(
                                          '@ ${Formatters.formatCurrency(event.unitCost)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppColors.textHint,
                                                fontSize: 10,
                                              ),
                                        ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        event.reason.isNotEmpty
                                            ? event.reason
                                            : 'Damaged stock',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        Formatters.formatDate(event.date),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textHint,
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
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Error loading damage history: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(damageEventListProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _openAddDamageDialog(context),
              backgroundColor: AppColors.error,
              icon: const Icon(Icons.report_problem_rounded),
              label: const Text('Record Damage'),
            )
          : null,
    );
  }

  void _openAddDamageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => DamageProductDialog(
        productType: _sectorFilter == 'mobile'
            ? 'mobile'
            : _sectorFilter == 'gadget'
                ? 'gadget'
                : null,
      ),
    );
  }
}
