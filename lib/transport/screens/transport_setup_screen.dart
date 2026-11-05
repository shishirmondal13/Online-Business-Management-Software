import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/l10n/app_localizations.dart';

import '../../shared/constants/app_colors.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/utils/calculations.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/transport_cost.dart';
import '../providers/transport_provider.dart';

/// Transport setup screen
class TransportSetupScreen extends ConsumerStatefulWidget {
  const TransportSetupScreen({super.key});

  @override
  ConsumerState<TransportSetupScreen> createState() =>
      _TransportSetupScreenState();
}

class _TransportSetupScreenState extends ConsumerState<TransportSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productCodeController = TextEditingController();
  final _productNameController = TextEditingController();
  final _perKgPriceController = TextEditingController();
  final _weightController = TextEditingController();

  double _perGramPrice = 0;
  double _transportCost = 0;
  TransportCost? _editingCost;

  @override
  void dispose() {
    _productCodeController.dispose();
    _productNameController.dispose();
    _perKgPriceController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _calculateValues() {
    final perKg = double.tryParse(_perKgPriceController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 0;
    setState(() {
      _perGramPrice = Calculations.calculatePerGramPrice(perKgPrice: perKg);
      _transportCost = Calculations.calculateTransportCost(
        perGramPrice: _perGramPrice,
        productWeightGrams: weight,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final transportList = ref.watch(transportCostListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transport)),
      body: Column(
        children: [
          // Form
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _editingCost != null ? l10n.edit : l10n.add,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _productCodeController,
                            label: l10n.productCode,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            controller: _productNameController,
                            label: l10n.productName,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppCurrencyField(
                            controller: _perKgPriceController,
                            label: l10n.perKgPrice,
                            onChanged: (_) => _calculateValues(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppNumberField(
                            controller: _weightController,
                            label: l10n.productWeight,
                            onChanged: (_) => _calculateValues(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.perGramPrice,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(Formatters.formatCurrency(_perGramPrice)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                l10n.transportCost,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                Formatters.formatCurrency(_transportCost),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: _editingCost != null
                                ? l10n.update
                                : l10n.save,
                            onPressed: _handleSave,
                          ),
                        ),
                        if (_editingCost != null) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppOutlinedButton(
                              text: l10n.cancel,
                              onPressed: _clearForm,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // List
          Expanded(
            child: transportList.when(
              data: (list) => list.isEmpty
                  ? Center(child: Text(l10n.noData))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final cost = list[index];
                        return ListTile(
                          title: Text(cost.productName),
                          subtitle: Text(
                            '${cost.productCode} - ${cost.productWeightGrams}g',
                          ),
                          trailing: Text(
                            Formatters.formatCurrency(cost.transportCost),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onTap: () => _editCost(cost),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
            ),
          ),
        ],
      ),
    );
  }

  void _editCost(TransportCost cost) {
    setState(() {
      _editingCost = cost;
      _productCodeController.text = cost.productCode;
      _productNameController.text = cost.productName;
      _perKgPriceController.text = cost.perKgPrice.toStringAsFixed(2);
      _weightController.text = cost.productWeightGrams.toStringAsFixed(2);
    });
    _calculateValues();
  }

  void _clearForm() {
    setState(() {
      _editingCost = null;
      _productCodeController.clear();
      _productNameController.clear();
      _perKgPriceController.clear();
      _weightController.clear();
      _perGramPrice = 0;
      _transportCost = 0;
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final cost = TransportCost.create(
      userId: userId,
      productCode: _productCodeController.text.trim(),
      productName: _productNameController.text.trim(),
      perKgPrice: double.tryParse(_perKgPriceController.text) ?? 0,
      productWeightGrams: double.tryParse(_weightController.text) ?? 0,
    );

    final service = ref.read(transportCostServiceProvider);
    if (_editingCost != null) {
      await service.updateTransportCost(
        cost.copyWith(id: _editingCost!.id, createdAt: _editingCost!.createdAt),
      );
    } else {
      await service.addTransportCost(cost);
    }
    _clearForm();
  }
}
