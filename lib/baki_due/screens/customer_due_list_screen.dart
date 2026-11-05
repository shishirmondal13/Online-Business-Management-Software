import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/utils/calculations.dart';
import '../../shared/widgets/app_table.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../sales/providers/sales_provider.dart';
import 'due_details_screen.dart';

class CustomerDueListScreen extends ConsumerStatefulWidget {
  const CustomerDueListScreen({super.key});

  @override
  ConsumerState<CustomerDueListScreen> createState() =>
      _CustomerDueListScreenState();
}

class _CustomerDueListScreenState extends ConsumerState<CustomerDueListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customersList = ref.watch(customersDueListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.bakiDue)),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppSearchField(
              controller: _searchController,
              hint: 'Search customers...',
              onChanged: (value) => setState(() {}),
              onClear: () => setState(() {}),
            ),
          ),

          Expanded(
            child: customersList.when(
              data: (list) {
                // Filter list based on search
                final filteredList = _searchController.text.isEmpty
                    ? list
                    : list.where((customer) {
                        final query = _searchController.text.toLowerCase();
                        return customer.name.toLowerCase().contains(query) ||
                            customer.contactNumber.contains(query);
                      }).toList();

                if (filteredList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: AppColors.success,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No pending dues!',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                final totalDue = filteredList.fold(
                  0.0,
                  (sum, c) => sum + c.remainingDue,
                );

                return Column(
                  children: [
                    // Total Due Summary
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha:0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.totalBaki,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          Text(
                            Formatters.formatCurrency(totalDue),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning,
                                ),
                          ),
                        ],
                      ),
                    ),

                    // Table
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: AppTable(
                          columns: [
                            AppTableColumn(label: l10n.customerName, flex: 3),
                            AppTableColumn(label: l10n.contactNumber, flex: 2),
                            AppTableColumn(
                              label: l10n.totalBaki,
                              flex: 2,
                              align: TextAlign.right,
                            ),
                            AppTableColumn(
                              label: 'Action',
                              flex: 1,
                              align: TextAlign.center,
                            ),
                          ],
                          rows: filteredList.map((customer) {
                            return AppTableRow(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DueDetailsScreen(customer: customer),
                                  ),
                                );
                              },
                              cells: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.warning,
                                      child: Text(
                                        customer.name.isNotEmpty
                                            ? customer.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        customer.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  customer.contactNumber,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                Text(
                                  Formatters.formatCurrency(
                                    customer.remainingDue,
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.error,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                  color: AppColors.textSecondary,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DueDetailsScreen(
                                          customer: customer,
                                        ),
                                      ),
                                    );
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
          ),
        ],
      ),
    );
  }
}
