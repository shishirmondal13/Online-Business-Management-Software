import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../mobile_sector/providers/mobile_provider.dart';
import '../../gadget_sector/providers/gadget_provider.dart';
import '../../sales/providers/sales_provider.dart';
import '../../expenses/providers/expense_provider.dart';
import '../../salary/providers/salary_provider.dart';

final exportServiceProvider = Provider<ExportService>(
  (ref) => ExportService(ref),
);

class ExportService {
  final Ref _ref;
  ExportService(this._ref);

  Future<Directory> _getTargetDownloadsDirectory() async {
    try {
      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          final winDownloads = Directory('$userProfile\\Downloads');
          if (await winDownloads.exists()) {
            return winDownloads;
          }
        }
      }
      final dir = await getDownloadsDirectory();
      if (dir != null) return dir;
    } catch (_) {}
    return await getApplicationDocumentsDirectory();
  }

  String _escapeCsv(Object? value) {
    if (value == null) return '';
    final str = value.toString();
    if (str.contains(',') ||
        str.contains('"') ||
        str.contains('\n') ||
        str.contains('\r')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }

  /// Export Mobile Stock, Gadgets, Sales, Expenses, and Salary to individual CSV files
  /// directly in the Downloads folder and opens the primary export file.
  Future<String> exportToCsv({String? specificModule}) async {
    final dir = await _getTargetDownloadsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    String primaryFilePath = '';

    final mobileList = await _ref.read(mobileStockListProvider.future);
    final gadgetList = await _ref.read(gadgetStockListProvider.future);
    final salesList = await _ref.read(salesListProvider.future);
    final expensesList = await _ref.read(expenseListProvider.future);
    final salaryList = await _ref.read(salaryListProvider.future);

    // 1. Mobile Stock CSV
    if (specificModule == null || specificModule == 'mobile') {
      final buffer = StringBuffer();
      buffer.writeln('Date,Model Name,IMEI Number,Purchase Rate,Transport Cost,Net Purchase Price,Selling Price,Profit,Status');
      for (final s in mobileList) {
        buffer.writeln([
          _escapeCsv(s.date.toString().split(' ')[0]),
          _escapeCsv(s.modelName),
          _escapeCsv(s.imeiNumber),
          _escapeCsv(s.purchaseRate),
          _escapeCsv(s.transportCost),
          _escapeCsv(s.netPurchasePrice),
          _escapeCsv(s.sellingPrice),
          _escapeCsv(s.profit),
          _escapeCsv(s.status),
        ].join(','));
      }
      final path = '${dir.path}/ibuzz_mobile_stock_$timestamp.csv';
      final file = File(path);
      await file.writeAsString(buffer.toString(), encoding: utf8);
      primaryFilePath = path;
    }

    // 2. Gadget Stock CSV
    if (specificModule == null || specificModule == 'gadget') {
      final buffer = StringBuffer();
      buffer.writeln('Date,Product Code,Product Name,Quantity,Purchase Price,Product Cost,Selling Price,Profit Margin,Status');
      for (final s in gadgetList) {
        buffer.writeln([
          _escapeCsv(s.date.toString().split(' ')[0]),
          _escapeCsv(s.productCode),
          _escapeCsv(s.productName),
          _escapeCsv(s.quantity),
          _escapeCsv(s.purchasePrice),
          _escapeCsv(s.productCost),
          _escapeCsv(s.sellingPrice),
          _escapeCsv(s.profitMargin),
          _escapeCsv(s.stockStatus),
        ].join(','));
      }
      final path = '${dir.path}/ibuzz_gadget_stock_$timestamp.csv';
      final file = File(path);
      await file.writeAsString(buffer.toString(), encoding: utf8);
      if (primaryFilePath.isEmpty) primaryFilePath = path;
    }

    // 3. Sales CSV
    if (specificModule == null || specificModule == 'sales') {
      final buffer = StringBuffer();
      buffer.writeln('Date,Product Type,Product ID,Product Name,Quantity,Selling Price,Total Amount,Paid Amount,Due Amount,Payment Status,Customer Name,Contact Number');
      for (final s in salesList) {
        buffer.writeln([
          _escapeCsv(s.date.toString().split(' ')[0]),
          _escapeCsv(s.productType),
          _escapeCsv(s.productId),
          _escapeCsv(s.productName),
          _escapeCsv(s.quantity),
          _escapeCsv(s.sellingPrice),
          _escapeCsv(s.totalAmount),
          _escapeCsv(s.paidAmount),
          _escapeCsv(s.dueAmount),
          _escapeCsv(s.paymentStatus),
          _escapeCsv(s.customerName),
          _escapeCsv(s.contactNumber),
        ].join(','));
      }
      final path = '${dir.path}/ibuzz_sales_$timestamp.csv';
      final file = File(path);
      await file.writeAsString(buffer.toString(), encoding: utf8);
      if (primaryFilePath.isEmpty) primaryFilePath = path;
    }

    // 4. Expenses CSV
    if (specificModule == null || specificModule == 'expenses') {
      final buffer = StringBuffer();
      buffer.writeln('Date,Category,Amount,Notes');
      for (final e in expensesList) {
        buffer.writeln([
          _escapeCsv(e.date.toString().split(' ')[0]),
          _escapeCsv(e.expenseType),
          _escapeCsv(e.amount),
          _escapeCsv(e.notes),
        ].join(','));
      }
      final path = '${dir.path}/ibuzz_expenses_$timestamp.csv';
      final file = File(path);
      await file.writeAsString(buffer.toString(), encoding: utf8);
      if (primaryFilePath.isEmpty) primaryFilePath = path;
    }

    // 5. Salary CSV
    if (specificModule == null || specificModule == 'salary') {
      final buffer = StringBuffer();
      buffer.writeln('Date,Employee Name,Amount,Advance,Bonus,Deductions,Notes');
      for (final s in salaryList) {
        buffer.writeln([
          _escapeCsv(s.date.toString().split(' ')[0]),
          _escapeCsv(s.employeeName),
          _escapeCsv(s.amount),
          _escapeCsv(s.advance),
          _escapeCsv(s.bonus),
          _escapeCsv(s.deductions),
          _escapeCsv(s.notes ?? ''),
        ].join(','));
      }
      final path = '${dir.path}/ibuzz_salary_$timestamp.csv';
      final file = File(path);
      await file.writeAsString(buffer.toString(), encoding: utf8);
      if (primaryFilePath.isEmpty) primaryFilePath = path;
    }

    if (primaryFilePath.isNotEmpty) {
      await OpenFile.open(primaryFilePath);
    }
    return primaryFilePath;
  }

  Future<void> exportToExcel() async {
    final excel = Excel.createExcel();

    // Mobile Stock Sheet
    final mobileSheet = excel['Mobile Stock'];
    mobileSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Model'),
      TextCellValue('IMEI'),
      TextCellValue('Purchase Rate'),
      TextCellValue('Transport'),
      TextCellValue('Net Price'),
      TextCellValue('Selling Price'),
      TextCellValue('Profit'),
      TextCellValue('Status'),
    ]);

    final mobileList = await _ref.read(mobileStockListProvider.future);
    for (final stock in mobileList) {
      mobileSheet.appendRow([
        TextCellValue(stock.date.toString().split(' ')[0]),
        TextCellValue(stock.modelName),
        TextCellValue(stock.imeiNumber),
        DoubleCellValue(stock.purchaseRate),
        DoubleCellValue(stock.transportCost),
        DoubleCellValue(stock.netPurchasePrice),
        DoubleCellValue(stock.sellingPrice),
        DoubleCellValue(stock.profit),
        TextCellValue(stock.status),
      ]);
    }

    // Gadget Stock Sheet
    final gadgetSheet = excel['Gadget Stock'];
    gadgetSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Code'),
      TextCellValue('Name'),
      TextCellValue('Qty'),
      TextCellValue('Product Cost'),
      TextCellValue('Selling Price'),
      TextCellValue('Profit'),
      TextCellValue('Status'),
    ]);

    final gadgetList = await _ref.read(gadgetStockListProvider.future);
    for (final stock in gadgetList) {
      gadgetSheet.appendRow([
        TextCellValue(stock.date.toString().split(' ')[0]),
        TextCellValue(stock.productCode),
        TextCellValue(stock.productName),
        IntCellValue(stock.quantity),
        DoubleCellValue(stock.productCost),
        DoubleCellValue(stock.sellingPrice),
        DoubleCellValue(stock.profit),
        TextCellValue(stock.stockStatus),
      ]);
    }

    // Sales Sheet
    final salesSheet = excel['Sales'];
    salesSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Product Type'),
      TextCellValue('Product Name'),
      TextCellValue('Quantity'),
      TextCellValue('Total Amount'),
      TextCellValue('Paid Amount'),
      TextCellValue('Due Amount'),
      TextCellValue('Customer Name'),
      TextCellValue('Status'),
    ]);

    final salesList = await _ref.read(salesListProvider.future);
    for (final sale in salesList) {
      salesSheet.appendRow([
        TextCellValue(sale.date.toString().split(' ')[0]),
        TextCellValue(sale.productType),
        TextCellValue(sale.productName),
        IntCellValue(sale.quantity),
        DoubleCellValue(sale.totalAmount),
        DoubleCellValue(sale.paidAmount),
        DoubleCellValue(sale.dueAmount),
        TextCellValue(sale.customerName),
        TextCellValue(sale.paymentStatus),
      ]);
    }

    // Save directly to Downloads folder
    final dir = await _getTargetDownloadsDirectory();
    final path =
        '${dir.path}/ibuzz_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(path);
    final bytes = excel.save();
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Failed to generate Excel data');
    }
    await file.writeAsBytes(bytes);
    await OpenFile.open(path);
  }

  Future<void> exportToPdf() async {
    final pdf = pw.Document();

    final mobileList = await _ref.read(mobileStockListProvider.future);
    final gadgetList = await _ref.read(gadgetStockListProvider.future);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, text: 'Smart Buy Online Report'),
          pw.Header(level: 1, text: 'Mobile Stock'),
          pw.TableHelper.fromTextArray(
            headers: [
              'Model',
              'IMEI',
              'Net Price',
              'Selling Price',
              'Profit',
              'Status',
            ],
            data: mobileList
                .map(
                  (s) => [
                    s.modelName,
                    s.imeiNumber,
                    s.netPurchasePrice.toStringAsFixed(2),
                    s.sellingPrice.toStringAsFixed(2),
                    s.profit.toStringAsFixed(2),
                    s.status,
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, text: 'Gadget Stock'),
          pw.TableHelper.fromTextArray(
            headers: ['Code', 'Name', 'Qty', 'Cost', 'Selling Price', 'Profit'],
            data: gadgetList
                .map(
                  (s) => [
                    s.productCode,
                    s.productName,
                    s.quantity.toString(),
                    s.productCost.toStringAsFixed(2),
                    s.sellingPrice.toStringAsFixed(2),
                    s.profit.toStringAsFixed(2),
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );

    final dir = await _getTargetDownloadsDirectory();
    final path =
        '${dir.path}/ibuzz_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(path);
  }
}
