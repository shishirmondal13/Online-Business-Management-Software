import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/utils/calculations.dart';
import '../../mobile_sector/providers/mobile_provider.dart';
import '../../gadget_sector/providers/gadget_provider.dart';
import '../../mobile_sector/screens/add_edit_mobile_screen.dart';
import '../../gadget_sector/screens/add_edit_gadget_screen.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mobileResults = ref.watch(searchMobileStockProvider(_query));
    final gadgetResults = ref.watch(searchGadgetStockProvider(_query));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.search)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppSearchField(
              controller: _searchController,
              hint: l10n.searchHere,
              onChanged: (v) => setState(() => _query = v),
              onClear: () => setState(() => _query = ''),
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 64, color: AppColors.textHint),
                        const SizedBox(height: 16),
                        Text('Search by IMEI, Product Code, or Name'),
                      ],
                    ),
                  )
                : ListView(
                    children: [
                      // Mobile Results
                      mobileResults.when(
                        data: (list) => list.isEmpty
                            ? const SizedBox()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      l10n.mobileStock,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: AppColors.mobileSector,
                                          ),
                                    ),
                                  ),
                                  ...list.map(
                                    (stock) => ListTile(
                                      leading: const Icon(
                                        Icons.smartphone,
                                        color: AppColors.mobileSector,
                                      ),
                                      title: Text(stock.modelName),
                                      subtitle: Text(stock.imeiNumber),
                                      trailing: Text(
                                        Formatters.formatCurrency(
                                          stock.sellingPrice,
                                        ),
                                      ),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddEditMobileScreen(
                                            mobileStock: stock,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        loading: () => const SizedBox(),
                        error: (_, _) => const SizedBox(),
                      ),
                      // Gadget Results
                      gadgetResults.when(
                        data: (list) => list.isEmpty
                            ? const SizedBox()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      l10n.gadgetStock,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: AppColors.gadgetSector,
                                          ),
                                    ),
                                  ),
                                  ...list.map(
                                    (stock) => ListTile(
                                      leading: const Icon(
                                        Icons.devices,
                                        color: AppColors.gadgetSector,
                                      ),
                                      title: Text(stock.productName),
                                      subtitle: Text(stock.productCode),
                                      trailing: Text(
                                        Formatters.formatCurrency(
                                          stock.sellingPrice,
                                        ),
                                      ),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddEditGadgetScreen(
                                            gadgetStock: stock,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        loading: () => const SizedBox(),
                        error: (_, _) => const SizedBox(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
