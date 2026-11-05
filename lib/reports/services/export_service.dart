import 'dart:io';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

import '../../mobile_sector/models/mobile_stock.dart';
import '../../gadget_sector/models/gadget_stock.dart';
import '../../sales/models/sale.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/report_provider.dart';

class ExportService {
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  late final NumberFormat _currencyFormat;
  
  ExportService() {
    _currencyFormat = NumberFormat.currency(
      symbol: '৳',
      decimalDigits: 2,
    );
  }

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

  Future<void> generatePdf({
    required DashboardData dashboardData,
    required List<Sale> sales,
    required List<MobileStock> mobileStock,
    required List<GadgetStock> gadgetStock,
    required List<ReportItem> profitHistory,
    required List<ReportItem> lossHistory,
  }) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.notoSansBengaliRegular();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font),
        build: (pw.Context context) {
          return [
            _buildHeader('Business Report'),
            pw.SizedBox(height: 20),
            _buildSummarySection(dashboardData),
            pw.SizedBox(height: 20),
            _buildSectionTitle('Profit & Loss History'),
            _buildProfitLossTable(profitHistory, lossHistory),
            pw.SizedBox(height: 20),
            _buildSectionTitle('Sales History'),
            _buildSalesTable(sales),
            pw.SizedBox(height: 20),
            _buildSectionTitle('Mobile Stock'),
            _buildMobileStockTable(mobileStock),
            pw.SizedBox(height: 20),
            _buildSectionTitle('Gadget Stock'),
            _buildGadgetStockTable(gadgetStock),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Business_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }

  pw.Widget _buildHeader(String title) {
    return pw.Header(
      level: 0,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Date: ${_dateFormat.format(DateTime.now())}'),
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10, top: 20),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _buildSummarySection(DashboardData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Financial Summary',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Total Sales', data.totalSales),
              _buildSummaryItem(
                'Total Cost',
                data.mobileStockValue + data.gadgetStockValue,
              ),
              _buildSummaryItem(
                'Total Profit',
                data.totalProfit,
                color: PdfColors.green,
              ),
              _buildSummaryItem(
                'Total Loss',
                data.totalLoss,
                color: PdfColors.red,
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Net Profit: ${_currencyFormat.format(data.netProfit)}',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, double value, {PdfColor? color}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.Text(
          _currencyFormat.format(value),
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildProfitLossTable(
    List<ReportItem> profits,
    List<ReportItem> losses,
  ) {
    final allItems = [...profits, ...losses];
    allItems.sort((a, b) => b.date.compareTo(a.date));

    return pw.TableHelper.fromTextArray(
      headers: ['Date', 'Item', 'Type', 'Amount'],
      data: allItems.map((item) {
        final isProfit = profits.contains(item);
        return [
          _dateFormat.format(item.date),
          item.name,
          isProfit ? 'Profit' : 'Loss',
          (isProfit ? '+' : '-') + _currencyFormat.format(item.amount),
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
      },
    );
  }

  pw.Widget _buildSalesTable(List<Sale> sales) {
    return pw.TableHelper.fromTextArray(
      headers: ['Date', 'Product', 'Qty', 'Price', 'Total'],
      data: sales
          .map(
            (sale) => [
              _dateFormat.format(sale.date),
              sale.productName,
              sale.quantity.toString(),
              _currencyFormat.format(sale.sellingPrice),
              _currencyFormat.format(sale.totalAmount),
            ],
          )
          .toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 10),
    );
  }

  pw.Widget _buildMobileStockTable(List<MobileStock> stock) {
    return pw.TableHelper.fromTextArray(
      headers: ['Model', 'IMEI', 'Purchase Price', 'Status'],
      data: stock
          .map(
            (item) => [
              item.modelName,
              item.imeiNumber,
              _currencyFormat.format(item.netPurchasePrice),
              item.status,
            ],
          )
          .toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 10),
    );
  }

  pw.Widget _buildGadgetStockTable(List<GadgetStock> stock) {
    return pw.TableHelper.fromTextArray(
      headers: ['Product', 'Code', 'Cost', 'Qty'],
      data: stock
          .map(
            (item) => [
              item.productName,
              item.productCode,
              _currencyFormat.format(item.productCost),
              item.quantity.toString(),
            ],
          )
          .toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 10),
    );
  }

  Future<void> generateExcel({
    required DashboardData dashboardData,
    required List<Sale> sales,
    required List<MobileStock> mobileStock,
    required List<GadgetStock> gadgetStock,
    required List<ReportItem> profitHistory,
    required List<ReportItem> lossHistory,
  }) async {
    final excel = Excel.createExcel();

    // Summary Sheet
    final summarySheet = excel['Summary'];
    summarySheet.appendRow([TextCellValue('Financial Summary')]);
    summarySheet.appendRow([
      TextCellValue('Date'),
      TextCellValue(_dateFormat.format(DateTime.now())),
    ]);
    summarySheet.appendRow([TextCellValue('')]);
    summarySheet.appendRow([TextCellValue('Metric'), TextCellValue('Value')]);
    summarySheet.appendRow([
      TextCellValue('Total Sales'),
      DoubleCellValue(dashboardData.totalSales),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total Cost'),
      DoubleCellValue(
        dashboardData.mobileStockValue + dashboardData.gadgetStockValue,
      ),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total Profit'),
      DoubleCellValue(dashboardData.totalProfit),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total Loss'),
      DoubleCellValue(dashboardData.totalLoss),
    ]);
    summarySheet.appendRow([
      TextCellValue('Net Profit'),
      DoubleCellValue(dashboardData.netProfit),
    ]);

    // Sales Sheet
    final salesSheet = excel['Sales'];
    salesSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Product'),
      TextCellValue('Type'),
      TextCellValue('Quantity'),
      TextCellValue('Selling Price'),
      TextCellValue('Total Amount'),
      TextCellValue('Profit'),
    ]);
    for (var sale in sales) {
      salesSheet.appendRow([
        TextCellValue(_dateFormat.format(sale.date)),
        TextCellValue(sale.productName),
        TextCellValue(sale.productType),
        IntCellValue(sale.quantity),
        DoubleCellValue(sale.sellingPrice),
        DoubleCellValue(sale.totalAmount),
        DoubleCellValue(sale.profit),
      ]);
    }

    // Mobile Stock Sheet
    final mobileSheet = excel['Mobile Stock'];
    mobileSheet.appendRow([
      TextCellValue('Model'),
      TextCellValue('IMEI'),
      TextCellValue('Purchase Price'),
      TextCellValue('Selling Price'),
      TextCellValue('Status'),
      TextCellValue('Date'),
    ]);
    for (var item in mobileStock) {
      mobileSheet.appendRow([
        TextCellValue(item.modelName),
        TextCellValue(item.imeiNumber),
        DoubleCellValue(item.netPurchasePrice),
        DoubleCellValue(item.sellingPrice),
        TextCellValue(item.status),
        TextCellValue(_dateFormat.format(item.createdAt)),
      ]);
    }

    // Gadget Stock Sheet
    final gadgetSheet = excel['Gadget Stock'];
    gadgetSheet.appendRow([
      TextCellValue('Product'),
      TextCellValue('Code'),
      TextCellValue('Cost'),
      TextCellValue('Selling Price'),
      TextCellValue('Quantity'),
      TextCellValue('Status'),
    ]);
    for (var item in gadgetStock) {
      gadgetSheet.appendRow([
        TextCellValue(item.productName),
        TextCellValue(item.productCode),
        DoubleCellValue(item.productCost),
        DoubleCellValue(item.sellingPrice),
        IntCellValue(item.quantity),
        TextCellValue(item.stockStatus),
      ]);
    }

    // Profit & Loss Sheet
    final plSheet = excel['Profit & Loss History'];
    plSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Item'),
      TextCellValue('Type'),
      TextCellValue('Amount'),
      TextCellValue('Status'),
    ]);

    for (var item in profitHistory) {
      plSheet.appendRow([
        TextCellValue(_dateFormat.format(item.date)),
        TextCellValue(item.name),
        TextCellValue(item.type),
        DoubleCellValue(item.amount),
        TextCellValue('Profit'),
      ]);
    }
    for (var item in lossHistory) {
      plSheet.appendRow([
        TextCellValue(_dateFormat.format(item.date)),
        TextCellValue(item.name),
        TextCellValue(item.type),
        DoubleCellValue(item.amount),
        TextCellValue('Loss'),
      ]);
    }

    // Save
    final fileBytes = excel.save();
    if (fileBytes != null) {
      final directory = await _getTargetDownloadsDirectory();
      final fileName =
          'Business_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(fileBytes);
      await OpenFile.open(file.path);
    }
  }

  Future<void> generateCsv({
    required DashboardData dashboardData,
    required List<Sale> sales,
    required List<MobileStock> mobileStock,
    required List<GadgetStock> gadgetStock,
    required List<ReportItem> profitHistory,
    required List<ReportItem> lossHistory,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('=== BUSINESS SUMMARY REPORT ===');
    buffer.writeln('Date,${_dateFormat.format(DateTime.now())}');
    buffer.writeln('Total Sales,${dashboardData.totalSales}');
    buffer.writeln('Total Profit,${dashboardData.totalProfit}');
    buffer.writeln('Total Loss,${dashboardData.totalLoss}');
    buffer.writeln('Net Balance,${dashboardData.totalProfit - dashboardData.totalLoss}');
    buffer.writeln('Mobile Stock Value,${dashboardData.mobileStockValue}');
    buffer.writeln('Gadget Stock Value,${dashboardData.gadgetStockValue}');
    buffer.writeln();

    buffer.writeln('=== SALES TRANSACTIONS ===');
    buffer.writeln('Date,Product Type,Product Name,Quantity,Selling Price,Total Amount,Paid Amount,Due Amount,Customer Name,Payment Status');
    for (final s in sales) {
      buffer.writeln([
        _dateFormat.format(s.date),
        s.productType,
        '"${s.productName.replaceAll('"', '""')}"',
        s.quantity,
        s.sellingPrice,
        s.totalAmount,
        s.paidAmount,
        s.dueAmount,
        '"${s.customerName.replaceAll('"', '""')}"',
        s.paymentStatus,
      ].join(','));
    }
    buffer.writeln();

    buffer.writeln('=== MOBILE STOCK ===');
    buffer.writeln('Date,Model Name,IMEI,Purchase Rate,Transport Cost,Net Price,Selling Price,Profit,Status');
    for (final s in mobileStock) {
      buffer.writeln([
        _dateFormat.format(s.date),
        '"${s.modelName.replaceAll('"', '""')}"',
        s.imeiNumber,
        s.purchaseRate,
        s.transportCost,
        s.netPurchasePrice,
        s.sellingPrice,
        s.profit,
        s.status,
      ].join(','));
    }
    buffer.writeln();

    buffer.writeln('=== GADGET STOCK ===');
    buffer.writeln('Date,Product Code,Product Name,Quantity,Product Cost,Selling Price,Profit Margin,Status');
    for (final s in gadgetStock) {
      buffer.writeln([
        _dateFormat.format(s.date),
        s.productCode,
        '"${s.productName.replaceAll('"', '""')}"',
        s.quantity,
        s.productCost,
        s.sellingPrice,
        s.profitMargin,
        s.stockStatus,
      ].join(','));
    }
    buffer.writeln();

    buffer.writeln('=== PROFIT & LOSS HISTORY ===');
    buffer.writeln('Date,Item Name,Type,Amount,Category');
    for (final p in profitHistory) {
      buffer.writeln([
        _dateFormat.format(p.date),
        '"${p.name.replaceAll('"', '""')}"',
        p.type,
        p.amount,
        'Profit',
      ].join(','));
    }
    for (final l in lossHistory) {
      buffer.writeln([
        _dateFormat.format(l.date),
        '"${l.name.replaceAll('"', '""')}"',
        l.type,
        l.amount,
        'Loss',
      ].join(','));
    }

    final directory = await _getTargetDownloadsDirectory();
    final fileName =
        'Business_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(buffer.toString());
    await OpenFile.open(file.path);
  }
}
