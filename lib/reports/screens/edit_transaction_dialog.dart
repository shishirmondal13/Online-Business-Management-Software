import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/constants/firestore_constants.dart';
import '../../sales/models/sale.dart';
import '../../salary/models/salary_payment.dart';
import '../../expenses/models/expense.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/services/firestore_helpers.dart';

// --- EDIT EXPENSE DIALOG ---
class EditExpenseDialog extends StatefulWidget {
  final AppExpense expense;
  const EditExpenseDialog({super.key, required this.expense});

  @override
  State<EditExpenseDialog> createState() => _EditExpenseDialogState();
}

class _EditExpenseDialogState extends State<EditExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountCtrl;
  late TextEditingController _notesCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.expense.amount.toString());
    _notesCtrl = TextEditingController(text: widget.expense.notes);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      double newAmount = double.tryParse(_amountCtrl.text) ?? 0;
      double diff = newAmount - widget.expense.amount;

      final batch = FirebaseFirestore.instance.batch();
      final expenseRef = FirebaseFirestore.instance
          .collection(FirestoreConstants.expenses)
          .doc(widget.expense.id);

      batch.update(expenseRef, {
        'amount': newAmount,
        'notes': _notesCtrl.text,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (diff != 0) {
        final capitalRef = await FirestoreHelpers.latestCapitalRef(
          FirebaseFirestore.instance,
          widget.expense.userId,
        );
        if (capitalRef != null) {
          batch.update(capitalRef, {
            FirestoreConstants.availableCapital: FieldValue.increment(-diff),
            FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      if (mounted) Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Expense'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'Amount',
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(label: 'Notes', controller: _notesCtrl),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// --- EDIT SALARY DIALOG ---
class EditSalaryDialog extends StatefulWidget {
  final SalaryPayment salary;
  const EditSalaryDialog({super.key, required this.salary});

  @override
  State<EditSalaryDialog> createState() => _EditSalaryDialogState();
}

class _EditSalaryDialogState extends State<EditSalaryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.salary.amount.toString());
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      double newAmount = double.tryParse(_amountCtrl.text) ?? 0;
      double newTotalDeduction =
          (newAmount +
              widget.salary.duePaid +
              widget.salary.advance +
              widget.salary.bonus) -
          widget.salary.deductions;

      double diffDeduction = newTotalDeduction - widget.salary.totalDeduction;

      final batch = FirebaseFirestore.instance.batch();

      // Update Salary
      batch.update(
        FirebaseFirestore.instance
            .collection(FirestoreConstants.salary)
            .doc(widget.salary.id),
        {'amount': newAmount, 'totalDeduction': newTotalDeduction},
      );

      final capitalRef = await FirestoreHelpers.latestCapitalRef(
        FirebaseFirestore.instance,
        widget.salary.userId,
      );
      if (capitalRef != null) {
        batch.update(capitalRef, {
          FirestoreConstants.availableCapital: FieldValue.increment(
            -diffDeduction,
          ),
          FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      if (mounted) Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Salary'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'Base Amount',
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// --- EDIT SALE DIALOG ---
class EditSaleDialog extends StatefulWidget {
  final Sale sale;
  const EditSaleDialog({super.key, required this.sale});

  @override
  State<EditSaleDialog> createState() => _EditSaleDialogState();
}

class _EditSaleDialogState extends State<EditSaleDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _sellingPriceCtrl;
  late TextEditingController _paidAmountCtrl;
  late TextEditingController _notesCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.sale.customerName);
    _contactCtrl = TextEditingController(text: widget.sale.contactNumber);
    _sellingPriceCtrl = TextEditingController(
      text: widget.sale.sellingPrice.toString(),
    );
    _paidAmountCtrl = TextEditingController(
      text: widget.sale.paidAmount.toString(),
    );
    _notesCtrl = TextEditingController(text: widget.sale.notes);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _paidAmountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final newSellingPrice = double.tryParse(_sellingPriceCtrl.text) ?? 0;
      final newPaidAmount = double.tryParse(_paidAmountCtrl.text) ?? 0;
      final newTotalAmount = newSellingPrice * widget.sale.quantity;
      final newDueAmount = newTotalAmount - newPaidAmount;

      if (newSellingPrice <= 0) {
        throw Exception('Selling price must be greater than 0');
      }
      if (newPaidAmount > newTotalAmount) {
        throw Exception('Paid amount cannot exceed total');
      }
      if (newDueAmount < 0) {
        throw Exception('Due amount cannot be negative');
      }

      final oldProductCost =
          (widget.sale.sellingPrice * widget.sale.quantity -
              widget.sale.profit) /
          widget.sale.quantity;
      final newProfit =
          (newSellingPrice - oldProductCost) * widget.sale.quantity;

      final diffDue = newDueAmount - widget.sale.dueAmount;
      final diffPaid = newPaidAmount - widget.sale.paidAmount;

      final batch = FirebaseFirestore.instance.batch();
      final firestore = FirebaseFirestore.instance;

      String status = FirestoreConstants.unpaid;
      if (newDueAmount <= 0.001 || newPaidAmount >= newTotalAmount - 0.001) {
        status = FirestoreConstants.paid;
      } else if (newPaidAmount > 0) {
        status = FirestoreConstants.partialPaid;
      }

      batch.update(
        firestore.collection(FirestoreConstants.sales).doc(widget.sale.id),
        {
          FirestoreConstants.customerName: _nameCtrl.text,
          FirestoreConstants.contactNumber: _contactCtrl.text,
          FirestoreConstants.sellingPrice: newSellingPrice,
          FirestoreConstants.totalAmount: newTotalAmount,
          FirestoreConstants.paidAmount: newPaidAmount,
          FirestoreConstants.dueAmount:
              newDueAmount <= 0.001 ? 0.0 : newDueAmount,
          FirestoreConstants.profit: newProfit,
          FirestoreConstants.paymentStatus: status,
          'notes': _notesCtrl.text.trim(),
          FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
        },
      );

      if (widget.sale.productType == FirestoreConstants.mobile) {
        batch.update(
          firestore
              .collection(FirestoreConstants.mobileStock)
              .doc(widget.sale.productId),
          {
            FirestoreConstants.sellingPrice: newSellingPrice,
            FirestoreConstants.profit: newSellingPrice - oldProductCost,
            FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
          },
        );
      }

      if (widget.sale.customerId.isNotEmpty) {
        batch.update(
          firestore
              .collection(FirestoreConstants.customers)
              .doc(widget.sale.customerId),
          {
            FirestoreConstants.name: _nameCtrl.text,
            FirestoreConstants.contactNumber: _contactCtrl.text,
            FirestoreConstants.totalDue: FieldValue.increment(diffDue),
            FirestoreConstants.totalPaid: FieldValue.increment(diffPaid),
            FirestoreConstants.remainingDue: FieldValue.increment(diffDue),
            FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
          },
        );
      }

      if (diffPaid != 0) {
        final adjustmentId = firestore
            .collection(FirestoreConstants.payments)
            .doc()
            .id;
        final adjustmentTime = DateTime.now();
        batch.set(
          firestore.collection(FirestoreConstants.payments).doc(adjustmentId),
          Payment(
            id: adjustmentId,
            userId: widget.sale.userId,
            customerId: widget.sale.customerId,
            saleId: widget.sale.id,
            date: adjustmentTime,
            amount: diffPaid,
            paymentMethod: 'adjustment',
            notes: 'Sale payment adjustment',
            createdAt: adjustmentTime,
            updatedAt: adjustmentTime,
          ).toMap(),
        );
        final capitalRef = await FirestoreHelpers.latestCapitalRef(
          firestore,
          widget.sale.userId,
        );
        if (capitalRef != null) {
          FirestoreHelpers.incrementCapitalPayment(batch, capitalRef, diffPaid);
        }
      }

      await batch.commit();

      if (mounted) Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Sale'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(label: 'Customer Name', controller: _nameCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Contact Number', controller: _contactCtrl),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Selling Price (Per Unit)',
                controller: _sellingPriceCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Paid Amount',
                controller: _paidAmountCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Sale Notes / Warranty / Remarks',
                controller: _notesCtrl,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
