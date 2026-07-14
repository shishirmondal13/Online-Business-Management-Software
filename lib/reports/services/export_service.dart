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
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'Business_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(fileBytes);
      await OpenFile.open(file.path);
    }
  }
}
