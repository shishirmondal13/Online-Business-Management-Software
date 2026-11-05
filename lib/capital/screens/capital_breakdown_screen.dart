import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
// import '../../shared/l10n/app_localizations.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/utils/calculations.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class CapitalBreakdownScreen extends ConsumerWidget {
  const CapitalBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final l10n = AppLocalizations.of(context)!;
    final dashboardData = ref.watch(dashboardDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Capital Breakdown')),
      body: dashboardData.when(
        data: (data) {
          final totalAssets =
              data.mobileStockValue +
              data.gadgetStockValue +
              data.availableCapital +
              data.totalBaki;

          // Avoid division by zero
          final safeTotal = totalAssets == 0 ? 1.0 : totalAssets;

          final sections = [
            _buildSectionData(
              value: data.mobileStockValue,
              total: safeTotal,
              color: AppColors.mobileSector,
              title: 'Mobile Stock',
            ),
            _buildSectionData(
              value: data.gadgetStockValue,
              total: safeTotal,
              color: AppColors.gadgetSector,
              title: 'Gadget Stock',
            ),
            _buildSectionData(
              value: data.availableCapital,
              total: safeTotal,
              color: AppColors.success,
              title: 'Cash in Hand',
            ),
            _buildSectionData(
              value: data.totalBaki,
              total: safeTotal,
              color: AppColors.warning,
              title: 'Due (Receivable)',
            ),
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.3,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildLegendItem(
                  context,
                  'Mobile Stock',
                  data.mobileStockValue,
                  AppColors.mobileSector,
                  safeTotal,
                ),
                _buildLegendItem(
                  context,
                  'Gadget Stock',
                  data.gadgetStockValue,
                  AppColors.gadgetSector,
                  safeTotal,
                ),
                _buildLegendItem(
                  context,
                  'Cash in Hand (Available)',
                  data.availableCapital,
                  AppColors.success,
                  safeTotal,
                ),
                _buildLegendItem(
                  context,
                  'Customer Due (Receivable)',
                  data.totalBaki,
                  AppColors.warning,
                  safeTotal,
                ),
                const Divider(height: 32),
                _buildTotalRow(context, totalAssets),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  PieChartSectionData _buildSectionData({
    required double value,
    required double total,
    required Color color,
    required String title,
  }) {
    final percentage = (value / total) * 100;
    return PieChartSectionData(
      color: color,
      value: value,
      title: '${percentage.toStringAsFixed(1)}%',
      radius: 50,
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    String title,
    double value,
    Color color,
    double total,
  ) {
    final percentage = (value / total) * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.formatCurrency(value),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(BuildContext context, double total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total Assets',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          Formatters.formatCurrency(total),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
