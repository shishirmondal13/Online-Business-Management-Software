import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// A premium, Excel-inspired data table with sticky headers and zebra striping
class AppTable extends StatelessWidget {
  final List<AppTableColumn> columns;
  final List<AppTableRow> rows;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const AppTable({
    super.key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tableBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Sticky Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(bottom: BorderSide(color: AppColors.tableBorder)),
            ),
            child: Row(
              children: columns
                  .map(
                    (col) => Expanded(
                      flex: col.flex,
                      child: Text(
                        col.label,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                        textAlign: col.align,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Scrollable Body
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : rows.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No data available',
                          style: TextStyle(color: AppColors.textHint),
                        ),
                        if (onRefresh != null)
                          TextButton.icon(
                            onPressed: onRefresh,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      final isEven = index % 2 == 0;

                      return Material(
                        color: isEven
                            ? Colors.transparent
                            : AppColors.background.withValues(alpha:0.5),
                        child: InkWell(
                          onTap: row.onTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.tableBorder.withValues(alpha:0.5),
                                ),
                              ),
                            ),
                            child: Row(
                              children: row.cells.asMap().entries.map((entry) {
                                final cellIndex = entry.key;
                                final cell = entry.value;
                                final col = columns[cellIndex];

                                return Expanded(
                                  flex: col.flex,
                                  child: DefaultTextStyle(
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(color: AppColors.textPrimary),
                                    textAlign: col.align,
                                    child: cell,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class AppTableColumn {
  final String label;
  final int flex;
  final TextAlign align;

  const AppTableColumn({
    required this.label,
    this.flex = 1,
    this.align = TextAlign.left,
  });
}

class AppTableRow {
  final List<Widget> cells;
  final VoidCallback? onTap;

  const AppTableRow({required this.cells, this.onTap});
}

/// Status pill widget for table cells
class AppStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool isOutline;

  const AppStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOutline ? Colors.transparent : color.withValues(alpha:0.1),
        border: Border.all(color: isOutline ? color : Colors.transparent),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
