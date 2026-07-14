import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../sales/models/sale.dart';
import '../utils/calculations.dart';

class ReceiptService {
  Future<void> generateReceipt(Sale sale) async {
    final pdf = pw.Document();

    // Load font if needed, but for now we'll use default
    // We can add a logo later if requested

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'Smart Buy Online',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Date: ${Formatters.formatDateTime(sale.date)}'),
              pw.Text('Receipt #: ${sale.id.substring(0, 8)}'),
              pw.Divider(),
              pw.Text('Customer: ${sale.customerName}'),
              pw.Text('Contact: ${sale.contactNumber}'),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [pw.Text('Item'), pw.Text('Price (Tk)')],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text('${sale.productName} x${sale.quantity}'),
                  ),
                  pw.Text('${sale.totalAmount.toStringAsFixed(2)} Tk'),
                ],
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total:'),
                  pw.Text(
                    '${sale.totalAmount.toStringAsFixed(2)} Tk',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Paid:'),
                  pw.Text('${sale.paidAmount.toStringAsFixed(2)} Tk'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Due:'),
                  pw.Text('${sale.dueAmount.toStringAsFixed(2)} Tk'),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('Thank you for your business!')),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Powered by I-buzz BD Management',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt_${sale.id.substring(0, 8)}',
    );
  }
}
