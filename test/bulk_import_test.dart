import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:excel/excel.dart';
import 'package:smart_buy_online/shared/constants/firestore_constants.dart';
import 'package:smart_buy_online/shared/services/bulk_import_service.dart';

void main() {
  group('Bulk Import Parsing Tests', () {
    test('CSV line parsing correctly handles commas inside quotes', () {
      final line = 'iPhone 15 Pro,"123,456,789012345",85000,92000';
      final List<String> result = [];
      final StringBuffer current = StringBuffer();
      bool inQuotes = false;

      for (int i = 0; i < line.length; i++) {
        final char = line[i];
        if (char == '"') {
          if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
            current.write('"');
            i++;
          } else {
            inQuotes = !inQuotes;
          }
        } else if (char == ',' && !inQuotes) {
          result.add(current.toString().trim());
          current.clear();
        } else {
          current.write(char);
        }
      }
      result.add(current.toString().trim());

      expect(result.length, 4);
      expect(result[0], 'iPhone 15 Pro');
      expect(result[1], '123,456,789012345');
      expect(result[2], '85000');
      expect(result[3], '92000');
    });

    test('Header normalization strips BOM, spaces, and punctuation', () {
      String normalizeHeader(String header) {
        return header
            .replaceAll('\uFEFF', '')
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), '');
      }

      expect(normalizeHeader('\uFEFFDate'), 'date');
      expect(normalizeHeader('Model Name'), 'modelname');
      expect(normalizeHeader('IMEI Number'), 'imeinumber');
      expect(normalizeHeader('Purchase Rate'), 'purchaserate');
      expect(normalizeHeader('Selling Price'), 'sellingprice');
    });

    test('Multi-section Business Report header recognition', () {
      final section1 = '=== BUSINESS SUMMARY REPORT ===';
      final section2 = '=== MOBILE STOCK ===';
      final section3 = '=== GADGET STOCK ===';

      String? detectSection(String line) {
        final clean = line
            .replaceAll('=', '')
            .replaceAll('-', '')
            .replaceAll('#', '')
            .replaceAll('[', '')
            .replaceAll(']', '')
            .trim()
            .toLowerCase();

        if (clean.contains('business summary')) return 'summary';
        if (clean.contains('mobile')) return FirestoreConstants.mobileStock;
        if (clean.contains('gadget')) return FirestoreConstants.gadgetStock;
        return null;
      }

      expect(detectSection(section1), 'summary');
      expect(detectSection(section2), FirestoreConstants.mobileStock);
      expect(detectSection(section3), FirestoreConstants.gadgetStock);
    });

    test('Excel workbook creation and cell extraction', () {
      final excel = Excel.createExcel();
      final sheetName = 'Mobile Stock';
      excel.rename('Sheet1', sheetName);
      final sheet = excel[sheetName];

      sheet.appendRow([
        TextCellValue('Model Name'),
        TextCellValue('IMEI'),
        TextCellValue('Purchase Rate'),
        TextCellValue('Selling Price'),
      ]);

      sheet.appendRow([
        TextCellValue('Samsung S24 Ultra'),
        TextCellValue('123456789012345'),
        DoubleCellValue(110000.0),
        DoubleCellValue(125000.0),
      ]);

      final bytes = excel.encode()!;
      expect(bytes.isNotEmpty, isTrue);

      final decoded = Excel.decodeBytes(bytes);
      expect(decoded.tables.containsKey('Mobile Stock'), isTrue);

      final table = decoded.tables['Mobile Stock']!;
      expect(table.rows.length, 2);
      expect(table.rows[0][0]?.value.toString(), contains('Model Name'));
      expect(table.rows[1][0]?.value.toString(), contains('Samsung S24 Ultra'));
    });

    test('IMEI cleaner strips formatting and scientific notation', () {
      String cleanImei(String raw) {
        if (raw.isEmpty) return '';
        if (raw.contains('E+') || raw.contains('e+')) {
          final d = double.tryParse(raw);
          if (d != null) return d.toStringAsFixed(0);
        }
        return raw.replaceAll(RegExp(r'[^0-9]'), '');
      }

      expect(cleanImei(' 861234-56-789012-3 '), '861234567890123');
      expect(cleanImei('861234567890123'), '861234567890123');
      expect(cleanImei('8.61234567890123E+14'), '861234567890123');
    });
  });
}
