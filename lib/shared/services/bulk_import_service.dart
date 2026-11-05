import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/firestore_constants.dart';

/// Result summary for a bulk import operation.
class BulkImportResult {
  final int totalRowsParsed;
  final int totalUploaded;
  final List<String> errors;
  final Map<String, int> collectionCounts;

  BulkImportResult({
    required this.totalRowsParsed,
    required this.totalUploaded,
    required this.errors,
    required this.collectionCounts,
  });
}

/// Progress callback reporting current progress (current, total, currentCollection).
typedef ImportProgressCallback =
    void Function(int current, int total, String currentCollection);

class BulkImportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Main entry point to import an Excel workbook (.xlsx) or CSV file into Firestore.
  /// Automatically matches sheet names or processes a specific target collection.
  Future<BulkImportResult> importExcelBytes({
    required Uint8List bytes,
    String? fileName,
    String? targetCollection,
    ImportProgressCallback? onProgress,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw StateError('You must be signed in to import data.');
    }

    final isCsv = fileName?.toLowerCase().endsWith('.csv') ?? false;
    if (isCsv) {
      return _importCsvBytes(
        bytes: bytes,
        fileName: fileName,
        userId: userId,
        targetCollection: targetCollection,
        onProgress: onProgress,
      );
    }

    return _importExcelWorkbook(
      bytes: bytes,
      fileName: fileName,
      userId: userId,
      targetCollection: targetCollection,
      onProgress: onProgress,
    );
  }

  Future<BulkImportResult> _importExcelWorkbook({
    required Uint8List bytes,
    String? fileName,
    required String userId,
    String? targetCollection,
    ImportProgressCallback? onProgress,
  }) async {
    final Excel excel = Excel.decodeBytes(bytes);
    int totalParsed = 0;
    int totalUploaded = 0;
    final List<String> errors = [];
    final Map<String, int> collectionCounts = {};
    final seenKeys = <String>{};

    final List<_PendingDoc> pendingDocs = [];

    for (final String sheetName in excel.tables.keys) {
      final Sheet? sheet = excel.tables[sheetName];
      if (sheet == null || sheet.rows.isEmpty) continue;

      // First row is header - normalize each header
      final List<Data?> headerRow = sheet.rows.first;
      final List<String> headers = headerRow
          .map((cell) => _normalizeHeader(_cellToString(cell)))
          .toList();

      String collection =
          (targetCollection != null && targetCollection.isNotEmpty)
              ? targetCollection
              : _mapSheetToCollection(sheetName);

      // If sheetName is generic (e.g. "Sheet1", "Data"), detect from headers or fileName
      if (collection.isEmpty) {
        collection = _detectCollectionFromHeaders(headers);
        if (collection.isEmpty && fileName != null) {
          collection = _detectCollectionForCsv(fileName: fileName, headers: headers);
        }
      }

      if (collection.isEmpty ||
          collection == 'summary' ||
          collection == 'history') {
        continue;
      }

      for (int i = 1; i < sheet.rows.length; i++) {
        final List<Data?> row = sheet.rows[i];
        if (_isRowEmpty(row)) continue;

        totalParsed++;
        try {
          final Map<String, dynamic> docData = _mapRowToDocData(
            collection: collection,
            headers: headers,
            row: row.map(_cellToString).toList(),
          );

          if (docData.isNotEmpty) {
            final validationError = _validateImportDoc(collection, docData);
            if (validationError != null) {
              throw FormatException(validationError);
            }
            final uniqueKey = _uniqueKey(collection, docData);
            if (uniqueKey != null && !seenKeys.add(uniqueKey)) {
              continue; // Duplicate entry in this workbook, skip without breaking
            }
            docData[FirestoreConstants.userId] = userId;
            pendingDocs.add(_PendingDoc(collection: collection, data: docData));
          }
        } catch (e) {
          errors.add('Sheet "$sheetName" Row ${i + 1}: $e');
        }
      }
    }

    // Now execute batch writes in chunks of 450 (Firestore limit is 500)
    const int chunkSize = 450;
    for (int i = 0; i < pendingDocs.length; i += chunkSize) {
      final end = (i + chunkSize < pendingDocs.length)
          ? i + chunkSize
          : pendingDocs.length;
      final chunk = pendingDocs.sublist(i, end);

      final WriteBatch batch = _firestore.batch();
      for (final doc in chunk) {
        final DocumentReference ref =
            _firestore.collection(doc.collection).doc();
        batch.set(ref, doc.data);
      }

      try {
        await batch.commit();
        totalUploaded += chunk.length;

        for (final doc in chunk) {
          collectionCounts[doc.collection] =
              (collectionCounts[doc.collection] ?? 0) + 1;
        }

        if (onProgress != null) {
          onProgress(totalUploaded, pendingDocs.length, chunk.last.collection);
        }
      } catch (e) {
        errors.add('Batch Write Error (Rows ${i + 1} to $end): $e');
      }
    }

    return BulkImportResult(
      totalRowsParsed: totalParsed,
      totalUploaded: totalUploaded,
      errors: errors,
      collectionCounts: collectionCounts,
    );
  }

  /// Multi-section & Smart Table CSV parser
  Future<BulkImportResult> _importCsvBytes({
    required Uint8List bytes,
    String? fileName,
    required String userId,
    String? targetCollection,
    ImportProgressCallback? onProgress,
  }) async {
    // 1. Strip BOM (\uFEFF) if present
    var csvString = utf8.decode(bytes);
    if (csvString.startsWith('\uFEFF')) {
      csvString = csvString.substring(1);
    }

    final lines = const LineSplitter().convert(csvString);
    if (lines.isEmpty) {
      return BulkImportResult(
        totalRowsParsed: 0,
        totalUploaded: 0,
        errors: ['CSV file is empty.'],
        collectionCounts: {},
      );
    }

    int totalParsed = 0;
    int totalUploaded = 0;
    final List<String> errors = [];
    final Map<String, int> collectionCounts = {};
    final seenKeys = <String>{};
    final List<_PendingDoc> pendingDocs = [];

    String currentCollection =
        (targetCollection != null && targetCollection.isNotEmpty)
            ? targetCollection
            : _detectCollectionForCsv(fileName: fileName, headers: []);
    List<String> currentHeaders = [];

    for (int i = 0; i < lines.length; i++) {
      final rawLine = lines[i].trim();
      if (rawLine.isEmpty) continue;

      // Check if line is a section header (e.g. === MOBILE STOCK === or [Mobile Stock] or ### Sales)
      final sectionMatch = _detectSectionHeader(rawLine);
      if (sectionMatch != null) {
        if (targetCollection == null || targetCollection.isEmpty) {
          currentCollection = sectionMatch;
        }
        currentHeaders = []; // Reset headers so next line is treated as section table header
        continue;
      }

      final row = _parseCsvLine(rawLine);
      if (row.isEmpty || row.every((c) => c.trim().isEmpty)) continue;

      // Check if row is a header row
      final normalizedRow = row.map(_normalizeHeader).toList();
      if (_isHeaderRow(normalizedRow)) {
        currentHeaders = normalizedRow;
        if (targetCollection == null || targetCollection.isEmpty) {
          final detected = _detectCollectionFromHeaders(currentHeaders);
          if (detected.isNotEmpty) {
            currentCollection = detected;
          }
        }
        continue;
      }

      // If we don't have headers yet, check if this is a summary metadata line (e.g. "Total Sales, 5000")
      if (currentHeaders.isEmpty) {
        continue;
      }

      // If current collection is not an uploadable database collection, skip gracefully
      if (currentCollection.isEmpty ||
          currentCollection == 'summary' ||
          currentCollection == 'history') {
        continue;
      }

      // Skip summary / divider rows in the middle of data
      if (row.length < 2 ||
          row[0].toLowerCase().startsWith('total') ||
          row[0].startsWith('===')) {
        continue;
      }

      totalParsed++;
      try {
        final Map<String, dynamic> docData = _mapRowToDocData(
          collection: currentCollection,
          headers: currentHeaders,
          row: row,
        );

        if (docData.isNotEmpty) {
          final validationError = _validateImportDoc(currentCollection, docData);
          if (validationError != null) {
            // Check if this row was just a subheader or non-data row
            if (_isProbablyNonDataRow(row)) {
              continue;
            }
            throw FormatException(validationError);
          }
          final uniqueKey = _uniqueKey(currentCollection, docData);
          if (uniqueKey != null && !seenKeys.add(uniqueKey)) {
            continue; // Skip duplicate without error
          }
          docData[FirestoreConstants.userId] = userId;
          pendingDocs.add(
            _PendingDoc(collection: currentCollection, data: docData),
          );
        }
      } catch (e) {
        errors.add('CSV Line ${i + 1}: $e');
      }
    }

    // Commit batches
    const int chunkSize = 450;
    for (int i = 0; i < pendingDocs.length; i += chunkSize) {
      final end = (i + chunkSize < pendingDocs.length)
          ? i + chunkSize
          : pendingDocs.length;
      final chunk = pendingDocs.sublist(i, end);

      final WriteBatch batch = _firestore.batch();
      for (final doc in chunk) {
        final DocumentReference ref =
            _firestore.collection(doc.collection).doc();
        batch.set(ref, doc.data);
      }

      try {
        await batch.commit();
        totalUploaded += chunk.length;

        for (final doc in chunk) {
          collectionCounts[doc.collection] =
              (collectionCounts[doc.collection] ?? 0) + 1;
        }

        if (onProgress != null) {
          onProgress(totalUploaded, pendingDocs.length, chunk.last.collection);
        }
      } catch (e) {
        errors.add('Batch Write Error (Rows ${i + 1} to $end): $e');
      }
    }

    return BulkImportResult(
      totalRowsParsed: totalParsed,
      totalUploaded: totalUploaded,
      errors: errors,
      collectionCounts: collectionCounts,
    );
  }

  /// Detect section banner like "=== MOBILE STOCK ===" or "[Sales]" or "### Expenses"
  String? _detectSectionHeader(String line) {
    final clean = line
        .replaceAll('=', '')
        .replaceAll('-', '')
        .replaceAll('#', '')
        .replaceAll('[', '')
        .replaceAll(']', '')
        .trim()
        .toLowerCase();

    if (clean.contains('business summary') ||
        clean.contains('summary report') ||
        clean.contains('overview')) {
      return 'summary';
    } else if (clean.contains('mobile') || clean.contains('phone stock')) {
      return FirestoreConstants.mobileStock;
    } else if (clean.contains('gadget') || clean.contains('accessory')) {
      return FirestoreConstants.gadgetStock;
    } else if (clean.contains('sale') ||
        clean.contains('transaction') ||
        clean.contains('invoice')) {
      return FirestoreConstants.sales;
    } else if (clean.contains('expense') ||
        clean.contains('cost') ||
        clean.contains('bill') ||
        clean.contains('rent')) {
      return FirestoreConstants.expenses;
    } else if (clean.contains('salary') ||
        clean.contains('payroll') ||
        clean.contains('employee')) {
      return FirestoreConstants.salary;
    } else if (clean.contains('capital') || clean.contains('invest')) {
      return FirestoreConstants.capital;
    } else if (clean.contains('transport') || clean.contains('courier')) {
      return FirestoreConstants.transportCosts;
    } else if (clean.contains('customer') || clean.contains('due')) {
      return FirestoreConstants.customers;
    } else if (clean.contains('profit') && clean.contains('loss')) {
      return 'history';
    }
    return null;
  }

  bool _isHeaderRow(List<String> row) {
    int matches = 0;
    const knownHeaderTokens = {
      'date',
      'model',
      'modelname',
      'imei',
      'imeinumber',
      'purchaserate',
      'sellingprice',
      'productname',
      'productcode',
      'quantity',
      'qty',
      'productcost',
      'purchaseprice',
      'producttype',
      'customername',
      'paidamount',
      'totalamount',
      'dueamount',
      'paymentstatus',
      'category',
      'expensetype',
      'amount',
      'notes',
      'employeename',
      'salary',
      'bonus',
      'deductions',
      'investorname',
      'title',
      'contactnumber',
      'profitmargin',
      'status',
      'netpurchasingprice',
      'netpurchaseprice',
      'netprice',
    };
    for (final cell in row) {
      if (knownHeaderTokens.contains(cell)) {
        matches++;
      }
    }
    return matches >= 2;
  }

  String _detectCollectionFromHeaders(List<String> headers) {
    final headerSet = headers.toSet();
    if (headerSet.contains('imei') ||
        headerSet.contains('imeinumber') ||
        headerSet.contains('purchaserate') ||
        headerSet.contains('netpurchasingprice') ||
        headerSet.contains('netpurchaseprice') ||
        headerSet.contains('netprice')) {
      return FirestoreConstants.mobileStock;
    }
    if (headerSet.contains('productcode') ||
        headerSet.contains('profitmargin') ||
        headerSet.contains('productcost') ||
        (headerSet.contains('productname') &&
            headerSet.contains('quantity') &&
            headerSet.contains('purchaseprice'))) {
      return FirestoreConstants.gadgetStock;
    }
    if (headerSet.contains('paidamount') ||
        headerSet.contains('totalamount') ||
        headerSet.contains('paymentstatus') ||
        headerSet.contains('contactnumber') ||
        headerSet.contains('producttype')) {
      return FirestoreConstants.sales;
    }
    if (headerSet.contains('expensetype') ||
        (headerSet.contains('category') && headerSet.contains('amount'))) {
      return FirestoreConstants.expenses;
    }
    if (headerSet.contains('employeename') ||
        headerSet.contains('bonus') ||
        headerSet.contains('deductions')) {
      return FirestoreConstants.salary;
    }
    if (headerSet.contains('investorname') || headerSet.contains('investor')) {
      return FirestoreConstants.capital;
    }
    if (headerSet.contains('customername') && headerSet.contains('totaldue')) {
      return FirestoreConstants.customers;
    }
    return '';
  }

  bool _isProbablyNonDataRow(List<String> row) {
    if (row.isEmpty) return true;
    final first = row[0].trim().toLowerCase();
    if (first.startsWith('total') ||
        first.startsWith('summary') ||
        first.startsWith('net') ||
        first.startsWith('===')) {
      return true;
    }
    return false;
  }

  /// Normalize column header by stripping BOM, non-alphanumeric, and whitespace
  String _normalizeHeader(String header) {
    return header
        .replaceAll('\uFEFF', '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Intelligently detect target collection for CSV from filename or header keys
  String _detectCollectionForCsv({
    String? fileName,
    required List<String> headers,
  }) {
    if (fileName != null) {
      final name = fileName.toLowerCase();
      if (name.contains('mobile') || name.contains('phone')) {
        return FirestoreConstants.mobileStock;
      } else if (name.contains('gadget') || name.contains('accessory')) {
        return FirestoreConstants.gadgetStock;
      } else if (name.contains('sale') || name.contains('invoice')) {
        return FirestoreConstants.sales;
      } else if (name.contains('expense') || name.contains('bill')) {
        return FirestoreConstants.expenses;
      } else if (name.contains('salary') || name.contains('payroll')) {
        return FirestoreConstants.salary;
      } else if (name.contains('capital') || name.contains('invest')) {
        return FirestoreConstants.capital;
      } else if (name.contains('transport')) {
        return FirestoreConstants.transportCosts;
      } else if (name.contains('customer') || name.contains('due')) {
        return FirestoreConstants.customers;
      }
    }

    final fromHeaders = _detectCollectionFromHeaders(headers);
    if (fromHeaders.isNotEmpty) return fromHeaders;

    return FirestoreConstants.mobileStock;
  }

  List<String> _parseCsvLine(String line) {
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
    return result;
  }

  /// Map sheet names (e.g. "Mobile Stock", "Sales", "Expenses") to Firestore collection names.
  String _mapSheetToCollection(String sheetName) {
    final name = sheetName.trim().toLowerCase().replaceAll(
      RegExp(r'[\s_-]+'),
      '',
    );
    if (name.contains('mobile') || name.contains('phone')) {
      return FirestoreConstants.mobileStock;
    } else if (name.contains('gadget') ||
        name.contains('item') ||
        name.contains('accessory')) {
      return FirestoreConstants.gadgetStock;
    } else if (name.contains('sale') ||
        name.contains('sell') ||
        name.contains('invoice')) {
      return FirestoreConstants.sales;
    } else if (name.contains('expense') ||
        name.contains('rent') ||
        name.contains('bill')) {
      return FirestoreConstants.expenses;
    } else if (name.contains('salary') ||
        name.contains('payroll') ||
        name.contains('employee')) {
      return FirestoreConstants.salary;
    } else if (name.contains('capital') || name.contains('invest')) {
      return FirestoreConstants.capital;
    } else if (name.contains('transport') || name.contains('courier')) {
      return FirestoreConstants.transportCosts;
    } else if (name.contains('customer') ||
        name.contains('baki') ||
        name.contains('due')) {
      return FirestoreConstants.customers;
    }
    return '';
  }

  /// Map row values based on column headers into Firestore schema format.
  Map<String, dynamic> _mapRowToDocData({
    required String collection,
    required List<String> headers,
    required List<String> row,
  }) {
    final Map<String, dynamic> rawMap = {};
    for (int i = 0; i < headers.length && i < row.length; i++) {
      final header = headers[i];
      if (header.isEmpty) continue;
      rawMap[header] = row[i];
    }

    final now = Timestamp.now();
    final Map<String, dynamic> doc = {
      FirestoreConstants.createdAt: now,
      FirestoreConstants.updatedAt: now,
    };

    switch (collection) {
      case FirestoreConstants.mobileStock:
        var model = _findValue(rawMap, [
          'modelname',
          'model',
          'name',
          'phone',
          'phonename',
          'devicename',
          'device',
          'item',
          'itemname',
          'product',
          'productname',
          'description',
          'particulars',
          'brand',
        ]);
        if (model.isEmpty && row.length > 1 && row[1].trim().isNotEmpty) {
          final candidate = row[1].trim();
          if (!RegExp(r'^\d{14,16}$').hasMatch(candidate)) {
            model = candidate;
          }
        }
        if (model.isEmpty) {
          model = 'Mobile Phone';
        }
        doc[FirestoreConstants.modelName] = model;

        final rawImei = _findValue(rawMap, [
          'imeinumber',
          'imei',
          'serial',
          'serialnumber',
          'barcode',
        ]);
        var imei = _cleanImei(rawImei);
        if (imei.length < 14) {
          for (final cell in row) {
            final cleaned = _cleanImei(cell);
            if (cleaned.length >= 14 && cleaned.length <= 16) {
              imei = cleaned;
              break;
            }
          }
        }
        doc[FirestoreConstants.imeiNumber] = imei;

        doc[FirestoreConstants.purchaseRate] = _parseDouble(rawMap, [
          'purchaserate',
          'purchaseprice',
          'cost',
          'buyprice',
          'price',
          'rate',
        ]);
        doc[FirestoreConstants.transportCost] = _parseDouble(rawMap, [
          'transportcost',
          'transport',
          'shipping',
          'courier',
        ]);
        doc[FirestoreConstants.netPurchasePrice] =
            (doc[FirestoreConstants.purchaseRate] as double) +
            (doc[FirestoreConstants.transportCost] as double);
        final importedSellingPrice = _parseDouble(rawMap, [
          'sellingprice',
          'sellprice',
          'saleprice',
        ]);
        doc[FirestoreConstants.sellingPrice] = importedSellingPrice > 0
            ? importedSellingPrice
            : (doc[FirestoreConstants.netPurchasePrice] as double);
        doc[FirestoreConstants.status] =
            _findValue(rawMap, ['status']).toLowerCase() == 'sold'
                ? FirestoreConstants.sold
                : FirestoreConstants.unsold;
        doc[FirestoreConstants.date] = _parseTimestamp(rawMap, [
          'date',
          'purchasedate',
          'createdat',
        ]);
        break;

      case FirestoreConstants.gadgetStock:
        var name = _findValue(rawMap, [
          'productname',
          'name',
          'item',
          'itemname',
          'gadget',
          'product',
          'description',
          'particulars',
        ]);
        if (name.isEmpty && row.length > 2 && row[2].trim().isNotEmpty) {
          name = row[2].trim();
        }
        if (name.isEmpty) name = 'Gadget Item';
        doc[FirestoreConstants.productName] = name;

        final rawCode = _findValue(rawMap, [
          'productcode',
          'code',
          'sku',
          'itemcode',
          'barcode',
        ]);
        doc[FirestoreConstants.productCode] = rawCode.isNotEmpty
            ? rawCode
            : 'GAD-${DateTime.now().millisecondsSinceEpoch % 100000}';
        doc[FirestoreConstants.quantity] = _parseInt(rawMap, [
          'quantity',
          'qty',
          'count',
          'stock',
        ]);
        doc[FirestoreConstants.purchasePrice] = _parseDouble(rawMap, [
          'purchaseprice',
          'cost',
          'buyprice',
          'purchaserate',
        ]);
        doc[FirestoreConstants.productCost] = _parseDouble(rawMap, [
          'productcost',
          'totalcost',
          'unitcost',
        ]);
        if ((doc[FirestoreConstants.productCost] as double) <= 0) {
          doc[FirestoreConstants.productCost] =
              doc[FirestoreConstants.purchasePrice];
        }
        final productCost = doc[FirestoreConstants.productCost] as double;
        final importedMargin = _parseDouble(rawMap, ['profitmargin', 'margin']);
        final importedSellingPrice = _parseDouble(rawMap, [
          'sellingprice',
          'sellprice',
          'price',
        ]);
        doc[FirestoreConstants.sellingPrice] = importedSellingPrice > 0
            ? importedSellingPrice
            : (productCost + (productCost * importedMargin / 100));
        doc[FirestoreConstants.profitMargin] = importedMargin;
        doc[FirestoreConstants.stockStatus] =
            (doc[FirestoreConstants.quantity] as int) > 0
                ? FirestoreConstants.inStock
                : FirestoreConstants.outOfStock;
        break;

      case FirestoreConstants.sales:
        doc[FirestoreConstants.productType] = _findValue(rawMap, [
          'producttype',
          'type',
          'sector',
          'category',
        ]).toLowerCase();
        if ((doc[FirestoreConstants.productType] as String).isEmpty) {
          doc[FirestoreConstants.productType] = 'gadget';
        }
        doc[FirestoreConstants.productId] = _findValue(rawMap, [
          'productid',
          'itemid',
          'code',
          'imei',
          'imeinumber',
          'productcode',
        ]);
        if ((doc[FirestoreConstants.productId] as String).isEmpty) {
          doc[FirestoreConstants.productId] =
              'INV-${DateTime.now().millisecondsSinceEpoch % 100000}';
        }
        var saleProdName = _findValue(rawMap, [
          'productname',
          'name',
          'modelname',
          'item',
          'description',
        ]);
        if (saleProdName.isEmpty) saleProdName = 'Sale Item';
        doc[FirestoreConstants.productName] = saleProdName;
        doc[FirestoreConstants.quantity] = _parseInt(rawMap, [
          'quantity',
          'qty',
          'count',
        ]);
        if ((doc[FirestoreConstants.quantity] as int) <= 0) {
          doc[FirestoreConstants.quantity] = 1;
        }
        doc[FirestoreConstants.sellingPrice] = _parseDouble(rawMap, [
          'sellingprice',
          'unitprice',
          'price',
          'rate',
        ]);
        final totalAmount = _parseDouble(rawMap, [
          'totalamount',
          'total',
          'amount',
          'netamount',
        ]);
        doc[FirestoreConstants.totalAmount] = totalAmount > 0
            ? totalAmount
            : ((doc[FirestoreConstants.sellingPrice] as double) *
                (doc[FirestoreConstants.quantity] as int));
        doc[FirestoreConstants.customerName] = _findValue(rawMap, [
          'customername',
          'customer',
          'client',
          'buyer',
        ]);
        if ((doc[FirestoreConstants.customerName] as String).isEmpty) {
          doc[FirestoreConstants.customerName] = 'Cash Customer';
        }
        doc[FirestoreConstants.contactNumber] = _findValue(rawMap, [
          'contactnumber',
          'contact',
          'phone',
          'mobile',
        ]);
        doc[FirestoreConstants.paidAmount] = _parseDouble(rawMap, [
          'paidamount',
          'paid',
          'cashreceived',
          'advance',
        ]);
        doc[FirestoreConstants.dueAmount] =
            (doc[FirestoreConstants.totalAmount] as double) -
            (doc[FirestoreConstants.paidAmount] as double);
        doc[FirestoreConstants.paymentStatus] =
            (doc[FirestoreConstants.dueAmount] as double) <= 0
                ? FirestoreConstants.paid
                : FirestoreConstants.partialPaid;
        doc[FirestoreConstants.date] = _parseTimestamp(rawMap, [
          'date',
          'saledate',
          'createdat',
        ]);
        break;

      case FirestoreConstants.expenses:
        var cat = _findValue(rawMap, [
          'category',
          'expensecategory',
          'expensetype',
          'type',
          'title',
          'name',
        ]);
        if (cat.isEmpty) cat = 'General Expense';
        doc['category'] = cat;
        doc[FirestoreConstants.amount] = _parseDouble(rawMap, [
          'amount',
          'cost',
          'price',
          'bill',
        ]);
        doc[FirestoreConstants.notes] = _findValue(rawMap, [
          'notes',
          'note',
          'description',
          'details',
        ]);
        doc[FirestoreConstants.date] = _parseTimestamp(rawMap, [
          'date',
          'expensedate',
          'createdat',
        ]);
        break;

      case FirestoreConstants.salary:
        var emp = _findValue(rawMap, [
          'employeename',
          'employee',
          'name',
          'staff',
          'person',
        ]);
        if (emp.isEmpty) emp = 'Staff Member';
        doc['employeeName'] = emp;
        doc[FirestoreConstants.amount] = _parseDouble(rawMap, [
          'amount',
          'salary',
          'paid',
          'total',
        ]);
        doc['monthYear'] =
            _findValue(rawMap, ['monthyear', 'month', 'period']);
        doc[FirestoreConstants.notes] = _findValue(rawMap, [
          'notes',
          'note',
          'bonus',
          'details',
        ]);
        doc[FirestoreConstants.date] = _parseTimestamp(rawMap, [
          'date',
          'paymentdate',
          'createdat',
        ]);
        break;

      case FirestoreConstants.capital:
        var inv = _findValue(rawMap, [
          'investorname',
          'investor',
          'name',
          'partner',
        ]);
        if (inv.isEmpty) inv = 'Investor';
        doc['investorName'] = inv;
        doc[FirestoreConstants.amount] = _parseDouble(rawMap, [
          'amount',
          'capital',
          'investment',
        ]);
        doc['type'] = _findValue(rawMap, ['type', 'action', 'category']);
        if ((doc['type'] as String).isEmpty) {
          doc['type'] = 'Owner Capital';
        }
        doc[FirestoreConstants.notes] = _findValue(rawMap, [
          'notes',
          'note',
          'details',
        ]);
        doc[FirestoreConstants.date] = _parseTimestamp(rawMap, [
          'date',
          'investmentdate',
          'createdat',
        ]);
        break;

      case FirestoreConstants.transportCosts:
        var title = _findValue(rawMap, [
          'title',
          'courier',
          'vehicle',
          'name',
          'description',
        ]);
        if (title.isEmpty) title = 'Transport';
        doc['title'] = title;
        doc[FirestoreConstants.amount] = _parseDouble(rawMap, [
          'amount',
          'cost',
          'price',
          'fee',
        ]);
        doc[FirestoreConstants.notes] = _findValue(rawMap, [
          'notes',
          'note',
          'details',
        ]);
        doc[FirestoreConstants.date] = _parseTimestamp(rawMap, [
          'date',
          'transportdate',
          'createdat',
        ]);
        break;

      default:
        rawMap.forEach((key, val) {
          doc[key] = val;
        });
        break;
    }

    return doc;
  }

  // --- Helper Methods ---

  String _cleanImei(String raw) {
    if (raw.isEmpty) return '';
    // If Excel read it as scientific notation e.g. 8.61234E+14
    if (raw.contains('E+') || raw.contains('e+')) {
      final d = double.tryParse(raw);
      if (d != null) {
        return d.toStringAsFixed(0);
      }
    }
    return raw.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String? _validateImportDoc(String collection, Map<String, dynamic> doc) {
    String text(String key) => (doc[key] ?? '').toString().trim();
    double number(String key) => (doc[key] as num?)?.toDouble() ?? 0;
    int integer(String key) => (doc[key] as num?)?.toInt() ?? 0;

    switch (collection) {
      case FirestoreConstants.mobileStock:
        final imei = text(FirestoreConstants.imeiNumber);
        if (imei.length < 14 || imei.length > 16) {
          return 'Mobile row requires a 14-16 digit IMEI number (got: "$imei").';
        }
        if (number(FirestoreConstants.purchaseRate) <= 0) {
          return 'Mobile row requires a valid purchase rate.';
        }
        break;

      case FirestoreConstants.gadgetStock:
        if (integer(FirestoreConstants.quantity) < 0) {
          return 'Gadget row quantity cannot be negative.';
        }
        if (number(FirestoreConstants.purchasePrice) <= 0 &&
            number(FirestoreConstants.productCost) <= 0) {
          return 'Gadget row requires a positive purchase price or product cost.';
        }
        break;

      case FirestoreConstants.sales:
        final total = number(FirestoreConstants.totalAmount);
        final paid = number(FirestoreConstants.paidAmount);
        if (total <= 0) {
          return 'Sale row requires positive total amount.';
        }
        if (paid < 0 || paid > total) {
          return 'Sale row paid amount must be between 0 and total amount.';
        }
        break;

      case FirestoreConstants.expenses:
        if (number(FirestoreConstants.amount) <= 0) {
          return 'Expense row requires a positive amount.';
        }
        break;

      case FirestoreConstants.salary:
        if (number(FirestoreConstants.amount) <= 0) {
          return 'Salary row requires a positive amount.';
        }
        break;

      case FirestoreConstants.capital:
      case FirestoreConstants.transportCosts:
        if (number(FirestoreConstants.amount) <= 0) {
          return 'Row requires a positive amount.';
        }
        break;

      case FirestoreConstants.customers:
        if (text(FirestoreConstants.name).isEmpty) {
          return 'Customer row requires a name.';
        }
        break;
    }
    return null;
  }

  String? _uniqueKey(String collection, Map<String, dynamic> doc) {
    switch (collection) {
      case FirestoreConstants.mobileStock:
        return '$collection:${doc[FirestoreConstants.imeiNumber]}';
      case FirestoreConstants.gadgetStock:
        return '$collection:${doc[FirestoreConstants.productCode]}';
      default:
        return null;
    }
  }

  String _cellToString(Data? cell) {
    if (cell == null || cell.value == null) return '';
    final val = cell.value;
    if (val is TextCellValue) return val.value.text ?? '';
    if (val is IntCellValue) return val.value.toString();
    if (val is DoubleCellValue) return val.value.toString();
    if (val is DateCellValue) {
      return '${val.year}-${val.month.toString().padLeft(2, '0')}-${val.day.toString().padLeft(2, '0')}';
    }
    if (val is DateTimeCellValue) {
      return '${val.year}-${val.month.toString().padLeft(2, '0')}-${val.day.toString().padLeft(2, '0')}';
    }
    if (val is BoolCellValue) return val.value.toString();
    return val.toString();
  }

  bool _isRowEmpty(List<Data?> row) {
    return row.every(
      (cell) => cell == null || _cellToString(cell).trim().isEmpty,
    );
  }

  String _findValue(Map<String, dynamic> map, List<String> possibleKeys) {
    for (final key in possibleKeys) {
      final cleanKey = key.replaceAll(RegExp(r'[^a-z0-9]'), '').toLowerCase();
      // 1. Exact check
      if (map.containsKey(cleanKey) &&
          map[cleanKey].toString().trim().isNotEmpty) {
        return map[cleanKey].toString().trim();
      }
      // 2. Normalized exact check
      for (final entry in map.entries) {
        final cleanEntryKey =
            entry.key.replaceAll(RegExp(r'[^a-z0-9]'), '').toLowerCase();
        if (cleanEntryKey == cleanKey &&
            entry.value != null &&
            entry.value.toString().trim().isNotEmpty) {
          return entry.value.toString().trim();
        }
      }
      // 3. Substring check (e.g. 'purchaserate' matches 'purchaseratetk')
      for (final entry in map.entries) {
        final cleanEntryKey =
            entry.key.replaceAll(RegExp(r'[^a-z0-9]'), '').toLowerCase();
        if ((cleanEntryKey.contains(cleanKey) ||
                cleanKey.contains(cleanEntryKey)) &&
            entry.value != null &&
            entry.value.toString().trim().isNotEmpty) {
          return entry.value.toString().trim();
        }
      }
    }
    return '';
  }

  double _parseDouble(Map<String, dynamic> map, List<String> possibleKeys) {
    var str = _findValue(map, possibleKeys).trim().replaceAll(',', '');
    if (str.isEmpty) return 0.0;
    // Strip currency symbols and letters if any (e.g. ৳, Tk, BDT, $)
    str = str.replaceAll(RegExp(r'[^0-9.-]'), '');
    final value = double.tryParse(str);
    if (value == null || !value.isFinite || value < 0) {
      return 0.0;
    }
    return value;
  }

  int _parseInt(Map<String, dynamic> map, List<String> possibleKeys) {
    var str = _findValue(map, possibleKeys).trim().replaceAll(',', '');
    if (str.isEmpty) return 0;
    str = str.replaceAll(RegExp(r'[^0-9-]'), '');
    final value = int.tryParse(str);
    if (value == null || value < 0) {
      return 0;
    }
    return value;
  }

  Timestamp _parseTimestamp(
    Map<String, dynamic> map,
    List<String> possibleKeys,
  ) {
    final dateStr = _findValue(map, possibleKeys).trim();
    if (dateStr.isNotEmpty) {
      final dt = DateTime.tryParse(dateStr);
      if (dt != null) {
        return Timestamp.fromDate(dt);
      }
      try {
        final dmyMatch =
            RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})').firstMatch(dateStr);
        if (dmyMatch != null) {
          final d = int.parse(dmyMatch.group(1)!);
          final m = int.parse(dmyMatch.group(2)!);
          final y = int.parse(dmyMatch.group(3)!);
          return Timestamp.fromDate(DateTime(y, m, d));
        }
      } catch (_) {}
    }
    return Timestamp.now();
  }
}

class _PendingDoc {
  final String collection;
  final Map<String, dynamic> data;

  _PendingDoc({required this.collection, required this.data});
}
