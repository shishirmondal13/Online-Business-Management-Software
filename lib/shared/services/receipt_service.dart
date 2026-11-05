import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../sales/models/sale.dart';
import '../constants/app_colors.dart';
import '../utils/calculations.dart';

class ReceiptService {
  /// Builds the structured, centered PDF invoice document.
  Future<pw.Document> generateDocument(Sale sale, {List<Payment> payments = const []}) async {
    final pdf = pw.Document();
    final receiptId = sale.id.length >= 8 ? sale.id.substring(0, 8) : sale.id;

    // Load fonts with fallback for offline safety
    pw.Font? regularFont;
    pw.Font? boldFont;
    try {
      regularFont = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoBold();
    } catch (_) {
      regularFont = null;
      boldFont = null;
    }

    final theme = (regularFont != null && boldFont != null)
        ? pw.ThemeData.withFont(base: regularFont, bold: boldFont)
        : pw.ThemeData.base();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 40),
        theme: theme,
        build: (pw.Context context) {
          final isPaid = sale.paymentStatus == 'paid';
          final isPartial = sale.paymentStatus == 'partial';
          final statusColor = isPaid
              ? PdfColors.green800
              : (isPartial ? PdfColors.orange800 : PdfColors.red800);
          final statusBg = isPaid
              ? PdfColors.green50
              : (isPartial ? PdfColors.orange50 : PdfColors.red50);
          final statusLabel = isPaid
              ? 'PAID'
              : (isPartial ? 'PARTIALLY PAID' : 'UNPAID / DUE');

          return pw.Center(
            child: pw.ConstrainedBox(
              constraints: const pw.BoxConstraints(maxWidth: 520),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // --- HEADER SECTION (Centered) ---
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'SMART BUY ONLINE',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 22,
                            color: PdfColors.blueGrey900,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Smart Mobile & Gadget Management',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 5,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.blueGrey800,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            'SALES INVOICE / CASH MEMO',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 11,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 20),

                  // --- METADATA & CUSTOMER ROW ---
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Customer Info Box
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(12),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.grey300,
                              width: 1,
                            ),
                            borderRadius: pw.BorderRadius.circular(6),
                            color: PdfColors.grey50,
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'BILLED TO',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey700,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                sale.customerName.isNotEmpty
                                    ? sale.customerName
                                    : 'Walk-in Customer',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12,
                                  color: PdfColors.blueGrey900,
                                ),
                              ),
                              if (sale.contactNumber.isNotEmpty) ...[
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  'Phone: ${sale.contactNumber}',
                                  style: const pw.TextStyle(
                                    fontSize: 10,
                                    color: PdfColors.grey800,
                                  ),
                                ),
                              ],
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'Type: ${sale.productType == 'mobile' ? 'Mobile Sector' : 'Gadget Sector'}',
                                style: const pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      pw.SizedBox(width: 16),

                      // Invoice Meta Box
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(12),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.grey300,
                              width: 1,
                            ),
                            borderRadius: pw.BorderRadius.circular(6),
                            color: PdfColors.grey50,
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'Invoice #:',
                                    style: const pw.TextStyle(
                                      fontSize: 10,
                                      color: PdfColors.grey700,
                                    ),
                                  ),
                                  pw.Text(
                                    'INV-${receiptId.toUpperCase()}',
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10,
                                      color: PdfColors.blueGrey900,
                                    ),
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 4),
                              pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'Date:',
                                    style: const pw.TextStyle(
                                      fontSize: 10,
                                      color: PdfColors.grey700,
                                    ),
                                  ),
                                  pw.Text(
                                    Formatters.formatDateTime(sale.date),
                                    style: const pw.TextStyle(
                                      fontSize: 10,
                                      color: PdfColors.grey800,
                                    ),
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 6),
                              pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'Status:',
                                    style: const pw.TextStyle(
                                      fontSize: 10,
                                      color: PdfColors.grey700,
                                    ),
                                  ),
                                  pw.Container(
                                    padding: const pw.EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: pw.BoxDecoration(
                                      color: statusBg,
                                      borderRadius: pw.BorderRadius.circular(3),
                                      border: pw.Border.all(
                                        color: statusColor,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: pw.Text(
                                      statusLabel,
                                      style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 9,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 16),

                  // --- ITEMS TABLE ---
                  pw.Table(
                    border: pw.TableBorder(
                      horizontalInside: const pw.BorderSide(
                        color: PdfColors.grey300,
                        width: 0.5,
                      ),
                      bottom: const pw.BorderSide(
                        color: PdfColors.grey400,
                        width: 1,
                      ),
                      top: const pw.BorderSide(
                        color: PdfColors.blueGrey800,
                        width: 1.5,
                      ),
                    ),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1),
                      1: const pw.FlexColumnWidth(5),
                      2: const pw.FlexColumnWidth(2),
                      3: const pw.FlexColumnWidth(3),
                      4: const pw.FlexColumnWidth(3),
                    },
                    children: [
                      // Header
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey200,
                        ),
                        children: [
                          _buildTableCell('SL', isHeader: true),
                          _buildTableCell('Item Description', isHeader: true),
                          _buildTableCell(
                            'Qty',
                            isHeader: true,
                            align: pw.TextAlign.center,
                          ),
                          _buildTableCell(
                            'Unit Price',
                            isHeader: true,
                            align: pw.TextAlign.right,
                          ),
                          _buildTableCell(
                            'Total',
                            isHeader: true,
                            align: pw.TextAlign.right,
                          ),
                        ],
                      ),
                      // Item Row
                      pw.TableRow(
                        children: [
                          _buildTableCell('1'),
                          _buildTableCell(sale.productName),
                          _buildTableCell(
                            '${sale.quantity}',
                            align: pw.TextAlign.center,
                          ),
                          _buildTableCell(
                            '${sale.sellingPrice.toStringAsFixed(2)} Tk',
                            align: pw.TextAlign.right,
                          ),
                          _buildTableCell(
                            '${sale.totalAmount.toStringAsFixed(2)} Tk',
                            align: pw.TextAlign.right,
                            isBold: true,
                          ),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 12),

                  // --- FINANCIAL SUMMARY & TOTALS ---
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Container(
                        width: 240,
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.grey300,
                            width: 1,
                          ),
                          borderRadius: pw.BorderRadius.circular(6),
                          color: PdfColors.grey50,
                        ),
                        child: pw.Column(
                          children: [
                            _buildSummaryRow(
                              'Subtotal / Total:',
                              '${sale.totalAmount.toStringAsFixed(2)} Tk',
                              isBold: true,
                            ),
                            pw.Divider(color: PdfColors.grey300, height: 10),
                            _buildSummaryRow(
                              'Paid Amount:',
                              '${sale.paidAmount.toStringAsFixed(2)} Tk',
                              color: PdfColors.green800,
                            ),
                            pw.SizedBox(height: 4),
                            _buildSummaryRow(
                              'Due Amount:',
                              '${sale.dueAmount.toStringAsFixed(2)} Tk',
                              color: sale.dueAmount > 0
                                  ? PdfColors.red800
                                  : PdfColors.grey800,
                              isBold: sale.dueAmount > 0,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // --- PAYMENT HISTORY SECTION (If Payments Exist) ---
                  if (payments.isNotEmpty) ...[
                    pw.SizedBox(height: 16),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(
                          color: PdfColors.blue200,
                          width: 1,
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'PAYMENT HISTORY',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                              color: PdfColors.blue900,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Table(
                            border: pw.TableBorder(
                              horizontalInside: const pw.BorderSide(
                                color: PdfColors.blue100,
                                width: 0.5,
                              ),
                              top: const pw.BorderSide(
                                color: PdfColors.blue300,
                                width: 1,
                              ),
                              bottom: const pw.BorderSide(
                                color: PdfColors.blue300,
                                width: 1,
                              ),
                            ),
                            columnWidths: {
                              0: const pw.FlexColumnWidth(1),
                              1: const pw.FlexColumnWidth(3),
                              2: const pw.FlexColumnWidth(3),
                              3: const pw.FlexColumnWidth(2),
                              4: const pw.FlexColumnWidth(3),
                            },
                            children: [
                              // Payment table header
                              pw.TableRow(
                                decoration: const pw.BoxDecoration(
                                  color: PdfColors.blue100,
                                ),
                                children: [
                                  _buildTableCell('#', isHeader: true),
                                  _buildTableCell('Date', isHeader: true),
                                  _buildTableCell('Amount', isHeader: true, align: pw.TextAlign.right),
                                  _buildTableCell('Method', isHeader: true, align: pw.TextAlign.center),
                                  _buildTableCell('Notes', isHeader: true),
                                ],
                              ),
                              // Payment rows
                              ...payments.asMap().entries.map((entry) {
                                final idx = entry.key + 1;
                                final p = entry.value;
                                return pw.TableRow(
                                  children: [
                                    _buildTableCell('$idx'),
                                    _buildTableCell(DateFormat('dd MMM yyyy').format(p.date)),
                                    _buildTableCell(
                                      '${p.amount.toStringAsFixed(2)} Tk',
                                      align: pw.TextAlign.right,
                                      isBold: true,
                                    ),
                                    _buildTableCell(
                                      p.paymentMethod.isNotEmpty ? p.paymentMethod : 'cash',
                                      align: pw.TextAlign.center,
                                    ),
                                    _buildTableCell(p.notes.isNotEmpty ? p.notes : '-'),
                                  ],
                                );
                              }),
                            ],
                          ),
                          pw.SizedBox(height: 6),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Total Payments: ${payments.length}',
                                style: const pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.blue800,
                                ),
                              ),
                              pw.Text(
                                'Total Paid: ${payments.fold<double>(0, (total, p) => total + p.amount).toStringAsFixed(2)} Tk',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 9,
                                  color: PdfColors.blue900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // --- FULLY PAID CONFIRMATION BANNER ---
                  if (isPaid) ...[
                    pw.SizedBox(height: 12),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green50,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(
                          color: PdfColors.green400,
                          width: 1.5,
                        ),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            'FULLY PAID',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 14,
                              color: PdfColors.green900,
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            '- Transaction Complete. No outstanding balance.',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.green800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // --- SALE NOTES / WARRANTY BOX (If Present) ---
                  if (sale.notes.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 16),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.amber50,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(
                          color: PdfColors.amber300,
                          width: 1,
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'SALE NOTES / WARRANTY / REMARKS:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                              color: PdfColors.amber900,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            sale.notes.trim(),
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.brown800,
                              lineSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  pw.Spacer(),

                  // --- FOOTER SECTION (Centered) ---
                  pw.Divider(color: PdfColors.grey400),
                  pw.SizedBox(height: 6),
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'Thank you for your business with Smart Buy Online!',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                            color: PdfColors.blueGrey900,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Please retain this invoice for any warranty claims or customer support.',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Powered by Smart Buy Online Management System',
                          style: const pw.TextStyle(
                            fontSize: 7,
                            color: PdfColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf;
  }

  /// Builds raw PDF bytes
  Future<Uint8List> buildPdfBytes(Sale sale, {List<Payment> payments = const []}) async {
    final pdf = await generateDocument(sale, payments: payments);
    return pdf.save();
  }

  /// Direct print / print preview
  Future<void> generateReceipt(Sale sale, {List<Payment> payments = const []}) async {
    await printReceipt(sale, payments: payments);
  }

  /// Direct print / print preview
  Future<void> printReceipt(Sale sale, {List<Payment> payments = const []}) async {
    final receiptId = sale.id.length >= 8 ? sale.id.substring(0, 8) : sale.id;
    final pdf = await generateDocument(sale, payments: payments);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_$receiptId',
    );
  }

  /// Downloads or saves the PDF.
  /// On web: opens browser print dialog (Save as PDF supported).
  /// On native: opens system print/save dialog.
  Future<void> downloadPdf(Sale sale, {BuildContext? context, List<Payment> payments = const []}) async {
    try {
      final receiptId =
          sale.id.length >= 8 ? sale.id.substring(0, 8) : sale.id;
      final timeStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'Invoice_${receiptId}_$timeStamp.pdf';
      final pdfBytes = await buildPdfBytes(sale, payments: payments);

      // Works on web (browser print → Save as PDF) and native (system print dialog)
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: fileName,
      );
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading invoice: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Share or export PDF
  Future<void> sharePdf(Sale sale, {List<Payment> payments = const []}) async {
    final receiptId = sale.id.length >= 8 ? sale.id.substring(0, 8) : sale.id;
    final pdfBytes = await buildPdfBytes(sale, payments: payments);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Invoice_$receiptId.pdf',
    );
  }

  /// Opens an interactive modal dialog allowing the user to Download, Print, or Share the invoice.
  Future<void> showInvoiceOptionsDialog(
    BuildContext context,
    Sale sale, {
    bool isNewSale = false,
  }) async {
    final receiptId = sale.id.length >= 8 ? sale.id.substring(0, 8) : sale.id;

    // Fetch payment history for this sale from Firestore
    List<Payment> payments = [];
    try {
      // First try fetching payments linked to this specific sale
      var paymentsSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('saleId', isEqualTo: sale.id)
          .orderBy('date')
          .get();

      if (paymentsSnapshot.docs.isEmpty && sale.customerId.isNotEmpty) {
        // Fallback: fetch payments by customer ID
        paymentsSnapshot = await FirebaseFirestore.instance
            .collection('payments')
            .where('customerId', isEqualTo: sale.customerId)
            .orderBy('date')
            .get();
      }

      payments = paymentsSnapshot.docs
          .map((doc) => Payment.fromFirestore(doc))
          .toList();
    } catch (_) {
      // Silently handle errors - receipt still works without payment history
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isNewSale
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isNewSale ? Icons.check_circle : Icons.receipt_long,
                  color: isNewSale ? AppColors.success : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isNewSale ? 'Sale Recorded!' : 'Sales Invoice',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Invoice #INV-${receiptId.toUpperCase()}',
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.tableBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customer: ${sale.customerName.isEmpty ? 'Walk-in' : sale.customerName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Bill:',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          Formatters.formatCurrency(sale.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Paid Amount:',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          Formatters.formatCurrency(sale.paidAmount),
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (sale.dueAmount > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Due Balance:',
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            Formatters.formatCurrency(sale.dueAmount),
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // --- Payment History Summary in Dialog ---
              if (payments.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history, size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 6),
                          Text(
                            'Payment History (${payments.length})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...payments.map((p) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd MMM yyyy').format(p.date),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              '${p.amount.toStringAsFixed(2)} Tk (${p.paymentMethod})',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ],
              if (sale.paymentStatus == 'paid') ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade400),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 18, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'FULLY PAID',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.download_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  'Download PDF',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Save PDF to Downloads and open file',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  downloadPdf(sale, context: context, payments: payments);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.print_rounded,
                    color: AppColors.info,
                  ),
                ),
                title: const Text(
                  'Print Invoice',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Open system print preview',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  printReceipt(sale, payments: payments);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.share_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
                title: const Text(
                  'Share Invoice',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Export and send via apps',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  sharePdf(sale, payments: payments);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontWeight: (isHeader || isBold)
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
          fontSize: isHeader ? 9 : 10,
          color: isHeader ? PdfColors.blueGrey900 : PdfColors.grey900,
        ),
      ),
    );
  }

  pw.Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: PdfColors.grey700,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? PdfColors.blueGrey900,
          ),
        ),
      ],
    );
  }
}
