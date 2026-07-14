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
import '../models/mobile_stock.dart';
import '../providers/mobile_provider.dart';

/// Add/Edit mobile stock screen
class AddEditMobileScreen extends ConsumerStatefulWidget {
  final MobileStock? mobileStock;

  const AddEditMobileScreen({super.key, this.mobileStock});

  bool get isEditing => mobileStock != null;

  @override
  ConsumerState<AddEditMobileScreen> createState() =>
      _AddEditMobileScreenState();
}

class _AddEditMobileScreenState extends ConsumerState<AddEditMobileScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _date;
  final _modelNameController = TextEditingController();
  final _imeiController = TextEditingController();
  final _purchaseRateController = TextEditingController();
  final _transportCostController = TextEditingController();
  final _sellingPriceController = TextEditingController();

  double _netPurchasePrice = 0;
  double _profit = 0;
  String _status = 'unsold';

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.isEditing) {
      final stock = widget.mobileStock!;
      _date = stock.date;
      _modelNameController.text = stock.modelName;
      _imeiController.text = stock.imeiNumber;
      _purchaseRateController.text = stock.purchaseRate.toStringAsFixed(2);
      _transportCostController.text = stock.transportCost.toStringAsFixed(2);
      _sellingPriceController.text = stock.sellingPrice.toStringAsFixed(2);
      _netPurchasePrice = stock.netPurchasePrice;
      _profit = stock.profit;
      _status = stock.status;
    } else {
      _date = DateTime.now();
    }
  }

  @override
  void dispose() {
    _modelNameController.dispose();
    _imeiController.dispose();
    _purchaseRateController.dispose();
    _transportCostController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  void _calculateValues() {
    final purchaseRate = double.tryParse(_purchaseRateController.text) ?? 0;
    final transportCost = double.tryParse(_transportCostController.text) ?? 0;
    final sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0;

    setState(() {
      _netPurchasePrice = Calculations.calculateNetPurchasePrice(
        purchaseRate: purchaseRate,
        transportCost: transportCost,
      );
      _profit = Calculations.calculateMobileProfit(
        sellingPrice: sellingPrice,
        netPurchasePrice: _netPurchasePrice,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formState = ref.watch(mobileStockFormProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? l10n.edit : l10n.addMobileStock),
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
                // Error Message
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

                // Date
                AppDateField(
                  value: _date,
                  label: l10n.date,
                  onChanged: (date) {
                    setState(() {
                      _date = date;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Model Name
                AppTextField(
                  controller: _modelNameController,
                  label: l10n.modelName,
                  hint: 'e.g., Samsung Galaxy S24',
                  prefixIcon: Icons.smartphone_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      Validators.required(value, fieldName: l10n.modelName),
                ),
                const SizedBox(height: 20),

                // IMEI Number
                AppTextField(
                  controller: _imeiController,
                  label: l10n.imeiNumber,
                  hint: 'e.g., 353456789012345',
                  prefixIcon: Icons.qr_code,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: Validators.imei,
                ),
                const SizedBox(height: 32),

                // Pricing Section
                _buildSectionTitle(context, 'Pricing'),
                const SizedBox(height: 16),

                // Purchase Rate
                AppCurrencyField(
                  controller: _purchaseRateController,
                  label: l10n.purchaseRate,
                  onChanged: (_) => _calculateValues(),
                  validator: (value) => Validators.positiveNumber(
                    value,
                    fieldName: l10n.purchaseRate,
                  ),
                ),
                const SizedBox(height: 20),

                // Transport Cost
                AppCurrencyField(
                  controller: _transportCostController,
                  label: l10n.transportCost,
                  onChanged: (_) => _calculateValues(),
                ),
                const SizedBox(height: 20),

                // Net Purchase Price (Auto)
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.netPurchasePrice,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '(${l10n.autoCalculated})',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                      Text(
                        Formatters.formatCurrency(_netPurchasePrice),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Selling Price and Profit (only for editing - when device is sold)
                if (widget.isEditing) ...[
                  // Selling Price
                  AppCurrencyField(
                    controller: _sellingPriceController,
                    label: l10n.sellingPrice,
                    onChanged: (_) => _calculateValues(),
                  ),
                  const SizedBox(height: 20),

                  // Profit (Auto)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _profit >= 0
                          ? AppColors.success.withValues(alpha:0.1)
                          : AppColors.error.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _profit >= 0
                            ? AppColors.success.withValues(alpha:0.3)
                            : AppColors.error.withValues(alpha:0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _profit >= 0 ? l10n.profit : l10n.loss,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: _profit >= 0
                                        ? AppColors.success
                                        : AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '(${l10n.autoCalculated})',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                        Text(
                          Formatters.formatCurrency(_profit.abs()),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _profit >= 0
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Status Toggle (only for editing)
                if (widget.isEditing) ...[
                  _buildSectionTitle(context, l10n.status),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'unsold',
                          label: Text(l10n.unsold),
                          icon: const Icon(Icons.inventory_2_outlined),
                        ),
                        ButtonSegment(
                          value: 'sold',
                          label: Text(l10n.sold),
                          icon: const Icon(Icons.check_circle_outline),
                        ),
                      ],
                      selected: {_status},
                      onSelectionChanged: (selected) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _status = selected.first;
                        });
                      },
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Save Button
                AppButton(
                  text: widget.isEditing ? l10n.update : l10n.save,
                  icon: widget.isEditing ? Icons.save_outlined : Icons.add,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _handleSave();
                  },
                ),

                const SizedBox(height: 16),

                // Cancel Button
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    // For new entries, selling price is 0 (will be set when sold)
    final sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0;

    final stock = MobileStock.create(
      userId: userId,
      date: _date,
      modelName: _modelNameController.text.trim(),
      imeiNumber: _imeiController.text.trim(),
      purchaseRate: double.tryParse(_purchaseRateController.text) ?? 0,
      transportCost: double.tryParse(_transportCostController.text) ?? 0,
      sellingPrice: sellingPrice,
      status: _status,
    );

    final mobileStock = widget.isEditing
        ? stock.copyWith(
            id: widget.mobileStock!.id,
            createdAt: widget.mobileStock!.createdAt,
          )
        : stock;

    final success = await ref
        .read(mobileStockFormProvider.notifier)
        .save(mobileStock, isEditing: widget.isEditing);

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _handleDelete() async {
    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.areYouSure),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await ref
          .read(mobileStockFormProvider.notifier)
          .delete(widget.mobileStock!.id);

      if (success && mounted) {
        Navigator.pop(context);
      }
    }
  }
}
