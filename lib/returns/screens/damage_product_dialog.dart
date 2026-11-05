import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/firestore_constants.dart';
import '../../shared/utils/calculations.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../mobile_sector/models/mobile_stock.dart';
import '../../mobile_sector/providers/mobile_provider.dart';
import '../../gadget_sector/models/gadget_stock.dart';
import '../../gadget_sector/providers/gadget_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/return_provider.dart';

class DamageProductDialog extends ConsumerStatefulWidget {
  final String? productType; // 'mobile' or 'gadget', null if selecting inside dialog
  final String? productId;
  final String? productName;
  final String? identifier;
  final double? unitCost;
  final int? maxQuantity;

  const DamageProductDialog({
    this.productType,
    this.productId,
    this.productName,
    this.identifier,
    this.unitCost,
    this.maxQuantity,
    super.key,
  });

  @override
  ConsumerState<DamageProductDialog> createState() =>
      _DamageProductDialogState();
}

class _DamageProductDialogState extends ConsumerState<DamageProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedProductType;
  String? _selectedProductId;
  String? _selectedProductName;
  String? _selectedIdentifier;
  double _selectedUnitCost = 0;
  int _maxAvailableQuantity = 1;

  late final TextEditingController _quantityController;
  late final TextEditingController _reasonController;
  late DateTime _damageDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedProductType = widget.productType ?? 'mobile';
    _selectedProductId = widget.productId;
    _selectedProductName = widget.productName;
    _selectedIdentifier = widget.identifier;
    _selectedUnitCost = widget.unitCost ?? 0;
    _maxAvailableQuantity = widget.maxQuantity ?? 1;

    _quantityController = TextEditingController(text: '1');
    _reasonController = TextEditingController();
    _damageDate = DateTime.now();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  bool get _isDirectMode => widget.productId != null;

  int get _parsedQuantity => int.tryParse(_quantityController.text) ?? 1;

  double get _totalLossValue => _selectedUnitCost * _parsedQuantity;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null || _selectedProductId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product first.')),
      );
      return;
    }

    final quantity = _parsedQuantity;
    if (quantity <= 0 || quantity > _maxAvailableQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Quantity must be between 1 and $_maxAvailableQuantity',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(returnServiceProvider).recordDamage(
            productType: _selectedProductType,
            productId: _selectedProductId!,
            quantity: quantity,
            reason: _reasonController.text.trim(),
            date: _damageDate,
          );

      // Invalidate relevant providers
      ref.invalidate(mobileStockListProvider);
      ref.invalidate(gadgetStockListProvider);
      ref.invalidate(damageEventListProvider);
      ref.invalidate(dashboardDataProvider);

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Damaged ${_selectedProductType == 'mobile' ? 'mobile' : 'gadget'} recorded successfully.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record damage: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _selectedProductType == 'mobile';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.report_problem_rounded,
                        color: AppColors.error,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Record Damaged Product',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          Text(
                            'Deducts from available stock and logs damage loss',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textHint),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Sector Segmented Selector (only if not opened in direct mode)
                if (!_isDirectMode) ...[
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'mobile',
                          label: Text('Mobile'),
                          icon: Icon(Icons.smartphone_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: 'gadget',
                          label: Text('Gadget'),
                          icon: Icon(Icons.headphones_rounded, size: 18),
                        ),
                      ],
                      selected: {_selectedProductType},
                      onSelectionChanged: (set) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedProductType = set.first;
                          _selectedProductId = null;
                          _selectedProductName = null;
                          _selectedIdentifier = null;
                          _selectedUnitCost = 0;
                          _maxAvailableQuantity = 1;
                          _quantityController.text = '1';
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Product Selector (if not direct mode)
                if (!_isDirectMode) ...[
                  if (isMobile)
                    Consumer(
                      builder: (context, ref, _) {
                        final unsoldMobiles = ref.watch(
                          filteredMobileStockProvider(FirestoreConstants.unsold),
                        );
                        return unsoldMobiles.when(
                          data: (list) {
                            return Autocomplete<MobileStock>(
                              optionsBuilder: (textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return list;
                                }
                                return list.where((m) {
                                  return m.modelName.toLowerCase().contains(
                                            textEditingValue.text.toLowerCase(),
                                          ) ||
                                      m.imeiNumber.toLowerCase().contains(
                                            textEditingValue.text.toLowerCase(),
                                          );
                                });
                              },
                              displayStringForOption: (option) =>
                                  '${option.modelName} (IMEI: ${option.imeiNumber})',
                              fieldViewBuilder:
                                  (context, controller, focusNode, onSubmitted) {
                                return AppTextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  label: 'Select Unsold Mobile *',
                                  prefixIcon: Icons.search,
                                  hint: 'Search by model or IMEI...',
                                  validator: (_) => _selectedProductId == null
                                      ? 'Please select a mobile product'
                                      : null,
                                );
                              },
                              onSelected: (stock) {
                                FocusScope.of(context).unfocus();
                                setState(() {
                                  _selectedProductId = stock.id;
                                  _selectedProductName = stock.modelName;
                                  _selectedIdentifier = stock.imeiNumber;
                                  _selectedUnitCost = stock.netPurchasePrice;
                                  _maxAvailableQuantity = 1;
                                  _quantityController.text = '1';
                                });
                              },
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Text('Error: $e'),
                        );
                      },
                    )
                  else
                    Consumer(
                      builder: (context, ref, _) {
                        final gadgets = ref.watch(gadgetStockListProvider);
                        return gadgets.when(
                          data: (list) {
                            final available =
                                list.where((g) => g.quantity > 0).toList();
                            return Autocomplete<GadgetStock>(
                              optionsBuilder: (textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return available;
                                }
                                return available.where((g) {
                                  return g.productName.toLowerCase().contains(
                                            textEditingValue.text.toLowerCase(),
                                          ) ||
                                      g.productCode.toLowerCase().contains(
                                            textEditingValue.text.toLowerCase(),
                                          );
                                });
                              },
                              displayStringForOption: (option) =>
                                  '${option.productName} (${option.productCode})',
                              fieldViewBuilder:
                                  (context, controller, focusNode, onSubmitted) {
                                return AppTextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  label: 'Select Gadget Stock *',
                                  prefixIcon: Icons.search,
                                  hint: 'Search by name or code...',
                                  validator: (_) => _selectedProductId == null
                                      ? 'Please select a gadget product'
                                      : null,
                                );
                              },
                              onSelected: (stock) {
                                FocusScope.of(context).unfocus();
                                setState(() {
                                  _selectedProductId = stock.id;
                                  _selectedProductName = stock.productName;
                                  _selectedIdentifier = stock.productCode;
                                  _selectedUnitCost = stock.productCost;
                                  _maxAvailableQuantity = stock.quantity;
                                  _quantityController.text = '1';
                                });
                              },
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Text('Error: $e'),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                ],

                // Selected Product Details Card
                if (_selectedProductName != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.tableBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isMobile
                              ? Icons.smartphone_rounded
                              : Icons.headphones_rounded,
                          color: isMobile
                              ? AppColors.mobileSector
                              : AppColors.gadgetSector,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedProductName!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (_selectedIdentifier != null &&
                                  _selectedIdentifier!.isNotEmpty)
                                Text(
                                  '${isMobile ? "IMEI" : "Code"}: $_selectedIdentifier',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              Text(
                                'Unit Cost: ${Formatters.formatCurrency(_selectedUnitCost)} • Max Available: $_maxAvailableQuantity',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Damage Date & Quantity Row
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AppDateField(
                        value: _damageDate,
                        label: 'Damage Date',
                        onChanged: (d) => setState(() => _damageDate = d),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: AppNumberField(
                        controller: _quantityController,
                        label: 'Quantity',
                        allowDecimal: false,
                        readOnly: isMobile, // Mobile is fixed 1
                        onChanged: (_) => setState(() {}),
                        validator: (val) {
                          final q = int.tryParse(val ?? '') ?? 0;
                          if (q <= 0) return 'Must be >= 1';
                          if (q > _maxAvailableQuantity) {
                            return 'Max $_maxAvailableQuantity';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Damage Reason Field
                AppTextField(
                  controller: _reasonController,
                  label: 'Damage Reason / Description *',
                  hint: 'e.g., Broken screen, water damage, motherboard dead',
                  prefixIcon: Icons.edit_note_rounded,
                  maxLines: 2,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter the damage reason';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Financial Loss Alert Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.trending_down_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Estimated Loss Value:',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        Formatters.formatCurrency(_totalLossValue),
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: AppOutlinedButton(
                        text: 'Cancel',
                        onPressed: _saving ? null : () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        text: 'Record Damage',
                        backgroundColor: AppColors.error,
                        isLoading: _saving,
                        icon: Icons.check_circle_outline,
                        onPressed: _saving ? null : _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
