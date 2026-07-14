import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../../mobile_sector/providers/mobile_provider.dart';
import '../../gadget_sector/providers/gadget_provider.dart';

final exportServiceProvider = Provider<ExportService>(
  (ref) => ExportService(ref),
);

class ExportService {
  final Ref _ref;
  ExportService(this._ref);

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

    // Save file
    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/ibuzz_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(path);
    await file.writeAsBytes(excel.encode()!);
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
          pw.Header(level: 0, text: 'I-Buzz BD Management Report'),
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

    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/ibuzz_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(path);
  }
}
