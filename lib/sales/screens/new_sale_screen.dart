import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/utils/calculations.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/sale.dart';
import '../providers/sales_provider.dart';
import '../../mobile_sector/providers/mobile_provider.dart';
import '../../gadget_sector/providers/gadget_provider.dart';
import '../../mobile_sector/models/mobile_stock.dart';
import '../../gadget_sector/models/gadget_stock.dart';

class NewSaleScreen extends ConsumerStatefulWidget {
  const NewSaleScreen({super.key});

  @override
  ConsumerState<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends ConsumerState<NewSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  String _productType = 'mobile'; // Default to mobile
  String? _selectedStockId;

  final _productNameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _sellingPriceController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _paidAmountController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  double _totalAmount = 0;
  double _dueAmount = 0;
  bool _isLoading = false;

  double _selectedProductCost = 0;
  int? _selectedStockQty;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _quantityController.dispose();
    _sellingPriceController.dispose();
    _customerNameController.dispose();
    _contactController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculate() {
    final qty = int.tryParse(_quantityController.text) ?? 1;
    final price = double.tryParse(_sellingPriceController.text) ?? 0;
    final paid = double.tryParse(_paidAmountController.text) ?? 0;
    setState(() {
      _totalAmount = price * qty;
      _dueAmount = _totalAmount - paid;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.newSale)),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, l10n.basicInfo),
              const SizedBox(height: 16),
              AppDateField(
                value: _date,
                label: l10n.date,
                onChanged: (d) => setState(() => _date = d),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'mobile',
                      label: Text(l10n.mobile),
                      icon: const Icon(Icons.smartphone),
                    ),
                    ButtonSegment(
                      value: 'gadget',
                      label: Text(l10n.gadget),
                      icon: const Icon(Icons.devices),
                    ),
                  ],
                  selected: {_productType},
                  onSelectionChanged: (s) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _productType = s.first;
                      _selectedStockId = null;
                      _selectedProductCost = 0;
                      _selectedStockQty = null;
                      _productNameController.clear();
                      _sellingPriceController.clear();
                      _quantityController.text = '1';
                      _calculate();
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
              const SizedBox(height: 20),

              // Product Selection
              if (_productType == 'mobile')
                Consumer(
                  builder: (context, ref, child) {
                    final stockAsync = ref.watch(
                      filteredMobileStockProvider('unsold'),
                    );
                    return stockAsync.when(
                      data: (stockList) {
                        return Autocomplete<MobileStock>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return stockList;
                            }
                            return stockList.where((stock) {
                              return stock.imeiNumber.toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              );
                            });
                          },
                          displayStringForOption: (MobileStock option) =>
                              '${option.modelName} - ${option.imeiNumber}',
                          fieldViewBuilder:
                              (
                                context,
                                controller,
                                focusNode,
                                onFieldSubmitted,
                              ) {
                                return AppTextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  label: 'Search Mobile by IMEI',
                                  prefixIcon: Icons.search,
                                  validator: (val) => _selectedStockId == null
                                      ? 'Please select a mobile'
                                      : null,
                                );
                              },
                          onSelected: (MobileStock stock) {
                            FocusScope.of(context).unfocus();
                            setState(() {
                              _selectedStockId = stock.id;
                              _selectedProductCost = stock.netPurchasePrice;
                              _selectedStockQty = 1; // mobile is always 1

                              if (_productNameController.text.isEmpty) {
                                _productNameController.text = stock.modelName;
                              }

                              final currentPrice = _sellingPriceController.text
                                  .trim();
                              bool shouldUpdatePrice =
                                  currentPrice.isEmpty ||
                                  currentPrice == '0' ||
                                  currentPrice == '0.00';

                              if (shouldUpdatePrice && stock.sellingPrice > 0) {
                                _sellingPriceController.text = stock
                                    .sellingPrice
                                    .toStringAsFixed(2);
                              }

                              if (_quantityController.text.isEmpty) {
                                _quantityController.text = '1';
                              }
                              _calculate();
                            });
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4.0,
                                borderRadius: BorderRadius.circular(8),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: 250,
                                    maxWidth:
                                        MediaQuery.of(context).size.width - 48,
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: options.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(option.modelName),
                                            ),
                                            if (option.isReturned ||
                                                option.returnCount > 0)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.warning
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: AppColors.warning
                                                        .withValues(alpha: 0.5),
                                                  ),
                                                ),
                                                child: Text(
                                                  option.returnLabel,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.warning,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        subtitle: Text(
                                          'IMEI: ${option.imeiNumber} • Cost: ${Formatters.formatCurrency(option.netPurchasePrice)}',
                                        ),
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Text('Error: $e'),
                    );
                  },
                )
              else
                Consumer(
                  builder: (context, ref, child) {
                    final stockAsync = ref.watch(gadgetStockListProvider);
                    return stockAsync.when(
                      data: (stockList) {
                        final availableStock = stockList
                            .where((s) => s.quantity > 0)
                            .toList();
                        return Autocomplete<GadgetStock>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return availableStock;
                            }
                            return availableStock.where((stock) {
                              return stock.productCode.toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              );
                            });
                          },
                          displayStringForOption: (GadgetStock option) =>
                              '${option.productCode} - ${option.productName}',
                          fieldViewBuilder:
                              (
                                context,
                                controller,
                                focusNode,
                                onFieldSubmitted,
                              ) {
                                return AppTextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  label: 'Search Gadget by Code',
                                  prefixIcon: Icons.search,
                                  validator: (val) => _selectedStockId == null
                                      ? 'Please select a gadget'
                                      : null,
                                );
                              },
                          onSelected: (GadgetStock stock) {
                            FocusScope.of(context).unfocus();
                            setState(() {
                              _selectedStockId = stock.id;
                              _selectedProductCost = stock.productCost;
                              _selectedStockQty = stock.quantity;

                              if (_productNameController.text.isEmpty) {
                                _productNameController.text = stock.productName;
                              }

                              final currentPrice = _sellingPriceController.text
                                  .trim();
                              bool shouldUpdatePrice =
                                  currentPrice.isEmpty ||
                                  currentPrice == '0' ||
                                  currentPrice == '0.00';

                              if (shouldUpdatePrice && stock.sellingPrice > 0) {
                                _sellingPriceController.text = stock
                                    .sellingPrice
                                    .toStringAsFixed(2);
                              }
                              _calculate();
                            });
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4.0,
                                borderRadius: BorderRadius.circular(8),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: 250,
                                    maxWidth:
                                        MediaQuery.of(context).size.width - 48,
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: options.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(option.productName),
                                            ),
                                            if (option.isReturned ||
                                                option.returnedQuantity > 0)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.warning
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: AppColors.warning
                                                        .withValues(alpha: 0.5),
                                                  ),
                                                ),
                                                child: Text(
                                                  option.returnLabel,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.warning,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        subtitle: Text(
                                          'Code: ${option.productCode} (${option.quantity} left) • Cost: ${Formatters.formatCurrency(option.productCost)}',
                                        ),
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Text('Error: $e'),
                    );
                  },
                ),

              const SizedBox(height: 20),

              // Quantity and Price
              Row(
                children: [
                  Expanded(
                    child: AppNumberField(
                      controller: _quantityController,
                      label: l10n.quantity,
                      allowDecimal: false,
                      readOnly:
                          _productType ==
                          'mobile', // Mobile quantity is fixed to 1
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppCurrencyField(
                      controller: _sellingPriceController,
                      label: l10n.sellingPrice,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.totalAmount,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      Formatters.formatCurrency(_totalAmount),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle(context, 'Customer'),
              const SizedBox(height: 16),
              AppTextField(
                controller: _customerNameController,
                label: l10n.customerName,
                prefixIcon: Icons.person_outline,
                validator: (val) {
                  if (_dueAmount > 0 && (val == null || val.isEmpty)) {
                    return 'Required for due sales';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _contactController,
                label: l10n.contactNumber,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (_dueAmount > 0 && (val == null || val.isEmpty)) {
                    return 'Required for due sales';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              _buildSectionTitle(context, 'Payment'),
              const SizedBox(height: 16),
              AppCurrencyField(
                controller: _paidAmountController,
                label: l10n.paidAmount,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _dueAmount > 0
                      ? AppColors.warning.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _dueAmount > 0
                        ? AppColors.warning.withValues(alpha: 0.3)
                        : AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dueAmount > 0 ? l10n.remainingDue : l10n.paid,
                      style: TextStyle(
                        color: _dueAmount > 0
                            ? AppColors.warning
                            : AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      Formatters.formatCurrency(_dueAmount.abs()),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _dueAmount > 0
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle(context, 'Sale Notes / Remarks'),
              const SizedBox(height: 16),
              AppTextField(
                controller: _notesController,
                label: 'Sale Notes / Warranty / Remarks (Optional)',
                hint: 'e.g., 1 Year Official Warranty, Screen Protector included, IMEI verified',
                prefixIcon: Icons.note_alt_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              AppButton(
                text: l10n.save,
                isLoading: _isLoading,
                icon: Icons.check_circle_outline,
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

    if (_selectedStockId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a product')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0;
      final quantity = int.tryParse(_quantityController.text) ?? 1;
      final paidAmount = double.tryParse(_paidAmountController.text) ?? 0;

      final totalAmount = sellingPrice * quantity;

      // Safety Validations
      if (sellingPrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Selling price must be greater than 0'),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      if (_selectedStockQty != null && quantity > _selectedStockQty!) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Only $_selectedStockQty available in stock'),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      if (paidAmount > totalAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Paid amount cannot exceed total sale amount'),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final profit = (sellingPrice - _selectedProductCost) * quantity;

      final sale = Sale.create(
        userId: userId,
        date: _date,
        productType: _productType,
        productId: _selectedStockId!,
        productName: _productNameController.text.trim(),
        quantity: quantity,
        sellingPrice: sellingPrice,
        customerId: '',
        customerName: _customerNameController.text.trim(),
        contactNumber: _contactController.text.trim(),
        paidAmount: double.tryParse(_paidAmountController.text) ?? 0,
        profit: profit,
        notes: _notesController.text.trim(),
      );

      // Keep sale creation independent from native printing. On Windows,
      // Printing.layoutPdf can fail inside the platform runner; the sale must
      // remain committed even when a receipt cannot be printed. Receipts remain
      // available from the Sales list after the transaction completes.
      await ref.read(salesServiceProvider).createSale(sale);

      if (mounted) {
        setState(() => _isLoading = false);
        await ref.read(receiptServiceProvider).showInvoiceOptionsDialog(
              context,
              sale,
              isNewSale: true,
            );
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
