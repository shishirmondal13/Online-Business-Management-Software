import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../sales/models/sale.dart';
import '../../mobile_sector/providers/mobile_provider.dart';
import '../../gadget_sector/providers/gadget_provider.dart';
import '../providers/return_provider.dart';

class ReturnSaleDialog extends ConsumerStatefulWidget {
  const ReturnSaleDialog({required this.sale, super.key});
  final Sale sale;

  @override
  ConsumerState<ReturnSaleDialog> createState() => _ReturnSaleDialogState();
}

class _ReturnSaleDialogState extends ConsumerState<ReturnSaleDialog> {
  late final TextEditingController _quantityController;
  late final TextEditingController _refundController;
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  String _condition = 'resalable';
  String _refundMethod = 'cash';
  bool _saving = false;

  int get _remaining => widget.sale.quantity - widget.sale.returnedQuantity;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
    _refundController = TextEditingController(
      text: widget.sale.sellingPrice.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _refundController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final refund = double.tryParse(_refundController.text) ?? -1;
    if (quantity <= 0 ||
        quantity > _remaining ||
        refund < 0 ||
        _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid quantity, refund, and reason.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(returnServiceProvider)
          .processReturn(
            saleId: widget.sale.id,
            quantity: quantity,
            condition: _condition,
            refundAmount: refund,
            reason: _reasonController.text.trim(),
            refundMethod: _refundMethod,
            notes: _notesController.text.trim(),
          );
      ref.invalidate(rawDamageEventsProvider);
      ref.invalidate(damageEventListProvider);
      ref.invalidate(mobileStockListProvider);
      ref.invalidate(gadgetStockListProvider);
      ref.invalidate(returnListProvider);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Return failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Return product'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${widget.sale.productName} • Remaining: $_remaining',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            TextField(
              controller: _refundController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Refund amount'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _condition,
              decoration: const InputDecoration(labelText: 'Product condition *'),
              items: const [
                DropdownMenuItem(
                  value: 'resalable',
                  child: Text('Good / Resalable (Stock +1)'),
                ),
                DropdownMenuItem(
                  value: 'damaged',
                  child: Text('Damaged (Damage Stock +1)'),
                ),
              ],
              onChanged: (value) => setState(() => _condition = value!),
            ),
            DropdownButtonFormField<String>(
              initialValue: _refundMethod,
              decoration: const InputDecoration(labelText: 'Refund method'),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'bank', child: Text('Bank')),
                DropdownMenuItem(
                  value: 'adjustment',
                  child: Text('Due adjustment'),
                ),
              ],
              onChanged: (value) => setState(() => _refundMethod = value!),
            ),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: 'Reason *'),
            ),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Process return'),
        ),
      ],
    );
  }
}
