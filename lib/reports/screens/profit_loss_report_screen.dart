import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/utils/calculations.dart';
import '../providers/report_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../sales/providers/sales_provider.dart';
import '../../mobile_sector/providers/mobile_provider.dart';
import '../../gadget_sector/providers/gadget_provider.dart';

class ProfitLossReportScreen extends ConsumerStatefulWidget {
  const ProfitLossReportScreen({super.key});

  @override
  ConsumerState<ProfitLossReportScreen> createState() =>
      _ProfitLossReportScreenState();
}

class _ProfitLossReportScreenState
    extends ConsumerState<ProfitLossReportScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _sector;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filter = ReportFilter(
      fromDate: _fromDate,
      toDate: _toDate,
      sector: _sector,
    );
    final reportStats = ref.watch(filteredReportStatsProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reports),
        actions: [
          if (_isExporting)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _showExportOptions(context),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.filter,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppDateField(
                          value: _fromDate,
                          label: l10n.from,
                          onChanged: (d) => setState(() => _fromDate = d),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppDateField(
                          value: _toDate,
                          label: l10n.to,
                          onChanged: (d) => setState(() => _toDate = d),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _sector,
                    decoration: InputDecoration(labelText: l10n.sector),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l10n.all)),
                      DropdownMenuItem(
                        value: 'mobile',
                        child: Text(l10n.mobile),
                      ),
                      DropdownMenuItem(
                        value: 'gadget',
                        child: Text(l10n.gadget),
                      ),
                    ],
                    onChanged: (v) => setState(() => _sector = v),
                  ),
                ],
              ),
            ),
          ),

          // Report Data
          Expanded(
            child: reportStats.when(
              data: (stats) => SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildReportCard(
                      context,
                      l10n.totalSales,
                      Formatters.formatCurrency(stats.totalSales),
                      Icons.point_of_sale,
                      AppColors.info,
                    ),
                    _buildReportCard(
                      context,
                      l10n.totalCost,
                      Formatters.formatCurrency(stats.totalCost),
                      Icons.inventory,
                      AppColors.textSecondary,
                    ),
                    _buildReportCard(
                      context,
                      l10n.totalProfit,
                      Formatters.formatCurrency(stats.totalProfit),
                      Icons.trending_up,
                      AppColors.success,
                    ),
                    _buildReportCard(
                      context,
                      l10n.totalLoss,
                      Formatters.formatCurrency(stats.totalLoss),
                      Icons.trending_down,
                      AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            stats.netProfit >= 0
                                ? AppColors.success
                                : AppColors.error,
                            stats.netProfit >= 0
                                ? AppColors.success.withValues(alpha: 0.7)
                                : AppColors.error.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            l10n.finalProfit,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            Formatters.formatCurrency(stats.netProfit),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Profit History',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer(
                      builder: (context, ref, child) {
                        final profitHistory = ref.watch(
                          profitHistoryProvider(filter),
                        );
                        return profitHistory.when(
                          data: (items) {
                            if (items.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No profit history found.'),
                              );
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.success
                                          .withValues(alpha: 0.1),
                                      child: const Icon(
                                        Icons.trending_up,
                                        color: AppColors.success,
                                      ),
                                    ),
                                    title: Text(item.name),
                                    subtitle: Text(
                                      Formatters.formatDateTime(item.date),
                                    ),
                                    trailing: Text(
                                      '+${Formatters.formatCurrency(item.amount)}',
                                      style: const TextStyle(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Text('Error: $e'),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Loss History',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer(
                      builder: (context, ref, child) {
                        final lossHistory = ref.watch(
                          lossHistoryProvider(filter),
                        );
                        return lossHistory.when(
                          data: (items) {
                            if (items.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No loss history found.'),
                              );
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.error
                                          .withValues(alpha: 0.1),
                                      child: const Icon(
                                        Icons.trending_down,
                                        color: AppColors.error,
                                      ),
                                    ),
                                    title: Text(item.name),
                                    subtitle: Text(
                                      Formatters.formatDateTime(item.date),
                                    ),
                                    trailing: Text(
                                      '-${Formatters.formatCurrency(item.amount)}',
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Text('Error: $e'),
                        );
                      },
                    ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text('Export to PDF'),
            onTap: () {
              Navigator.pop(context);
              _handleExport(isPdf: true);
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_chart, color: Colors.green),
            title: const Text('Export to Excel'),
            onTap: () {
              Navigator.pop(context);
              _handleExport(isPdf: false);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport({required bool isPdf}) async {
    setState(() => _isExporting = true);

    try {
      // Fetch all necessary data
      final filter = ReportFilter(
        fromDate: _fromDate,
        toDate: _toDate,
        sector: _sector,
      );
      final stats = await ref.read(filteredReportStatsProvider(filter).future);

      // Construct DashboardData from stats for export
      // Note: Capital fields will be 0 as they are not part of report stats
      final dashboardData = DashboardData(
        totalSales: stats.totalSales,
        totalProfit: stats.totalProfit,
        totalLoss: stats.totalLoss,
        mobileStockValue: stats.mobileStockValue,
        gadgetStockValue: stats.gadgetStockValue,
      );

      final sales = await ref.read(salesListProvider.future);
      final mobileStock = await ref.read(mobileStockListProvider.future);
      final gadgetStock = await ref.read(gadgetStockListProvider.future);

      final profitHistory = await ref.read(
        profitHistoryProvider(filter).future,
      );
      final lossHistory = await ref.read(lossHistoryProvider(filter).future);

      final exportService = ref.read(exportServiceProvider);

      if (isPdf) {
        await exportService.generatePdf(
          dashboardData: dashboardData,
          sales: sales,
          mobileStock: mobileStock,
          gadgetStock: gadgetStock,
          profitHistory: profitHistory,
          lossHistory: lossHistory,
        );
      } else {
        await exportService.generateExcel(
          dashboardData: dashboardData,
          sales: sales,
          mobileStock: mobileStock,
          gadgetStock: gadgetStock,
          profitHistory: profitHistory,
          lossHistory: lossHistory,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}
