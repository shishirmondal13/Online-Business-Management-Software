import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../shared/l10n/app_localizations.dart';

import '../../shared/constants/app_colors.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/utils/validators.dart';
import '../../shared/utils/calculations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transport/providers/transport_provider.dart';
import '../models/gadget_stock.dart';
import '../providers/gadget_provider.dart';

/// Add/Edit gadget stock screen
class AddEditGadgetScreen extends ConsumerStatefulWidget {
  final GadgetStock? gadgetStock;

  const AddEditGadgetScreen({super.key, this.gadgetStock});

  bool get isEditing => gadgetStock != null;

  @override
  ConsumerState<AddEditGadgetScreen> createState() =>
      _AddEditGadgetScreenState();
}

class _AddEditGadgetScreenState extends ConsumerState<AddEditGadgetScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _date;
  final _productCodeController = TextEditingController();
  final _productNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _transportCostController = TextEditingController();
  final _packagingCostController = TextEditingController();
  final _storageCostController = TextEditingController();
  final _marketingCostController = TextEditingController();
  final _damageCostController = TextEditingController();
  final _otherCostsController = TextEditingController();

  double _productCost = 0;
  double _totalCost = 0;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.isEditing) {
      final stock = widget.gadgetStock!;
      _date = stock.date;
      _productCodeController.text = stock.productCode;
      _productNameController.text = stock.productName;
      _quantityController.text = stock.quantity.toString();
      _purchasePriceController.text = stock.purchasePrice.toStringAsFixed(2);
      _transportCostController.text = stock.transportCost.toStringAsFixed(2);
      _packagingCostController.text = stock.packagingCost.toStringAsFixed(2);
      _storageCostController.text = stock.storageCost.toStringAsFixed(2);
      _marketingCostController.text = stock.marketingCost.toStringAsFixed(2);
      _damageCostController.text = stock.damageCost.toStringAsFixed(2);
      _otherCostsController.text = stock.otherCosts.toStringAsFixed(2);
      _productCost = stock.productCost;
      _totalCost = _productCost * stock.quantity;
    } else {
      _date = DateTime.now();
    }
  }

  @override
  void dispose() {
    _productCodeController.dispose();
    _productNameController.dispose();
    _quantityController.dispose();
    _purchasePriceController.dispose();
    _transportCostController.dispose();
    _packagingCostController.dispose();
    _storageCostController.dispose();
    _marketingCostController.dispose();
    _damageCostController.dispose();
    _otherCostsController.dispose();
    super.dispose();
  }

  void _calculateValues() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0;
    final transportCost = double.tryParse(_transportCostController.text) ?? 0;
    final packagingCost = double.tryParse(_packagingCostController.text) ?? 0;
    final storageCost = double.tryParse(_storageCostController.text) ?? 0;
    final marketingCost = double.tryParse(_marketingCostController.text) ?? 0;
    final damageCost = double.tryParse(_damageCostController.text) ?? 0;
    final otherCosts = double.tryParse(_otherCostsController.text) ?? 0;

    setState(() {
      _productCost = GadgetStock.calculateProductCost(
        purchasePrice: purchasePrice,
        transportCost: transportCost,
        packagingCost: packagingCost,
        storageCost: storageCost,
        marketingCost: marketingCost,
        damageCost: damageCost,
        otherCosts: otherCosts,
      );

      _totalCost = _productCost * quantity;
    });
  }

  Future<void> _loadTransportCost() async {
    final productCode = _productCodeController.text.trim();
    if (productCode.isEmpty) return;

    final transportCost = await ref.read(
      transportCostForProductProvider(productCode).future,
    );
    if (transportCost != null && mounted) {
      setState(() {
        _transportCostController.text = transportCost.transportCost
            .toStringAsFixed(2);
      });
      _calculateValues();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formState = ref.watch(gadgetStockFormProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? l10n.edit : l10n.addGadgetStock),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
              onPressed: _handleDelete,
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: formState.isLoading,
        message: l10n.saving,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (formState.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha:0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            formState.error!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Basic Info Section
                _buildSectionTitle(context, l10n.basicInfo),
                const SizedBox(height: 16),
                AppDateField(
                  value: _date,
                  label: l10n.date,
                  onChanged: (date) => setState(() => _date = date),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _productCodeController,
                  label: l10n.productCode,
                  hint: 'e.g., GAD-001',
                  prefixIcon: Icons.qr_code,
                  validator: Validators.productCode,
                  onChanged: (_) => _loadTransportCost(),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _productNameController,
                  label: l10n.productName,
                  hint: 'e.g., Wireless Earbuds',
                  prefixIcon: Icons.headphones_outlined,
                  validator: (v) =>
                      Validators.required(v, fieldName: l10n.productName),
                ),
                const SizedBox(height: 20),
                AppNumberField(
                  controller: _quantityController,
                  label: l10n.quantity,
                  allowDecimal: false,
                  validator: Validators.quantity,
                  onChanged: (_) => _calculateValues(),
                ),
                const SizedBox(height: 32),

                // Cost Breakdown Section
                _buildSectionTitle(context, l10n.costBreakdown),
                const SizedBox(height: 16),
                AppCurrencyField(
                  controller: _purchasePriceController,
                  label: l10n.purchasePrice,
                  onChanged: (_) => _calculateValues(),
                ),
                const SizedBox(height: 20),
                AppCurrencyField(
                  controller: _transportCostController,
                  label: l10n.transportCost,
                  onChanged: (_) => _calculateValues(),
                ),
                const SizedBox(height: 20),
                AppCurrencyField(
                  controller: _packagingCostController,
                  label: l10n.packagingCost,
                  onChanged: (_) => _calculateValues(),
                ),
                const SizedBox(height: 20),
                AppCurrencyField(
                  controller: _storageCostController,
                  label: l10n.storageCost,
                  onChanged: (_) => _calculateValues(),
                ),
                const SizedBox(height: 20),
                AppCurrencyField(
                  controller: _marketingCostController,
                  label: l10n.marketingCost,
                  onChanged: (_) => _calculateValues(),
                ),
                const SizedBox(height: 20),
                AppCurrencyField(
                  controller: _damageCostController,
                  label: l10n.damageCost,
                  onChanged: (_) => _calculateValues(),
                ),
                const SizedBox(height: 20),
                AppCurrencyField(
                  controller: _otherCostsController,
                  label: l10n.otherCosts,
                  onChanged: (_) => _calculateValues(),
                ),
                const SizedBox(height: 20),

                // Product Cost Auto
                Container(
                  padding: const EdgeInsets.all(20),
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
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.productCost,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          Text(
                            Formatters.formatCurrency(_productCost),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Cost',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          Text(
                            Formatters.formatCurrency(_totalCost),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                const SizedBox(height: 32),

                AppButton(
                  text: widget.isEditing ? l10n.update : l10n.save,
                  icon: widget.isEditing ? Icons.save_outlined : Icons.add,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _handleSave();
                  },
                ),
                const SizedBox(height: 16),
                AppOutlinedButton(
                  text: l10n.cancel,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) => Text(
    title,
    style: Theme.of(context).textTheme.titleLarge?.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.bold,
    ),
  );

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final stock = GadgetStock.create(
      userId: userId,
      date: _date,
      productCode: _productCodeController.text.trim(),
      productName: _productNameController.text.trim(),
      quantity: int.parse(_quantityController.text),
      purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0,
      transportCost: double.tryParse(_transportCostController.text) ?? 0,
      packagingCost: double.tryParse(_packagingCostController.text) ?? 0,
      storageCost: double.tryParse(_storageCostController.text) ?? 0,
      marketingCost: double.tryParse(_marketingCostController.text) ?? 0,
      damageCost: double.tryParse(_damageCostController.text) ?? 0,
      otherCosts: double.tryParse(_otherCostsController.text) ?? 0,
      profitMargin: 0,
      sellingPriceOverride: 0,
    );

    final gadgetStock = widget.isEditing
        ? stock.copyWith(
            id: widget.gadgetStock!.id,
            createdAt: widget.gadgetStock!.createdAt,
          )
        : stock;
    final success = await ref
        .read(gadgetStockFormProvider.notifier)
        .save(gadgetStock, isEditing: widget.isEditing);
    if (success && mounted) Navigator.pop(context);
  }

  Future<void> _handleDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.areYouSure),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final success = await ref
          .read(gadgetStockFormProvider.notifier)
          .delete(widget.gadgetStock!.id);
      if (success && mounted) Navigator.pop(context);
    }
  }
}
