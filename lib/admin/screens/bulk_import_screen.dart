import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/firestore_constants.dart';
import '../../shared/services/bulk_import_service.dart';
import '../../shared/services/data_audit_service.dart';
import '../../settings/services/export_service.dart';
import '../../mobile_sector/providers/mobile_provider.dart';
import '../../gadget_sector/providers/gadget_provider.dart';
import '../../sales/providers/sales_provider.dart';
import '../../expenses/providers/expense_provider.dart';
import '../../salary/providers/salary_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class BulkImportScreen extends ConsumerStatefulWidget {
  const BulkImportScreen({super.key});

  @override
  ConsumerState<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends ConsumerState<BulkImportScreen> {
  static const _maxImportBytes = 20 * 1024 * 1024;
  final BulkImportService _importService = BulkImportService();
  final DataAuditService _auditService = DataAuditService();
  final TextEditingController _filePathController = TextEditingController();

  bool _isUploading = false;
  bool _isAuditing = false;
  bool _isExporting = false;
  double _uploadProgress = 0.0;
  int _currentDocCount = 0;
  int _totalDocCount = 0;
  String _activeCollection = '';
  String? _selectedTargetCollection;

  final Map<String, String> _collectionOptions = {
    'Auto-Detect (All Sheets in File)': '',
    'Mobile Stock (mobile_stock)': FirestoreConstants.mobileStock,
    'Gadget Items (gadget_stock)': FirestoreConstants.gadgetStock,
    'Sales Invoices (sales)': FirestoreConstants.sales,
    'Expenses & Rent (expenses)': FirestoreConstants.expenses,
    'Employee Salary (salary)': FirestoreConstants.salary,
    'Capital & Investment (capital)': FirestoreConstants.capital,
    'Transport Costs (transport_costs)': FirestoreConstants.transportCosts,
    'Customers & Dues (customers)': FirestoreConstants.customers,
  };

  @override
  void dispose() {
    _filePathController.dispose();
    super.dispose();
  }

  /// 1-Click: Pick file and immediately begin uploading
  Future<void> _pickAndUploadFile() async {
    try {
      final files = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        dialogTitle: 'Select Excel (.xlsx) or CSV (.csv) to Upload',
      );
      if (files != null && files.isNotEmpty) {
        final path = files.first.path;
        if (path != null) {
          setState(() {
            _filePathController.text = path;
          });
          await _startImport();
        }
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e', isError: true);
    }
  }

  Future<void> _pickFile() async {
    try {
      final files = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        dialogTitle: 'Select Excel (.xlsx) or CSV (.csv) File',
      );
      if (files != null && files.isNotEmpty) {
        final path = files.first.path;
        if (path != null) {
          setState(() {
            _filePathController.text = path;
          });
        }
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e', isError: true);
    }
  }

  Future<void> _startImport() async {
    final path = _filePathController.text.trim();
    if (path.isEmpty) {
      _showSnackBar(
        'Please select or enter a valid file (.xlsx or .csv)',
        isError: true,
      );
      return;
    }

    final file = File(path);
    if (!await file.exists()) {
      _showSnackBar(
        'File not found at specified path. Please check the path.',
        isError: true,
      );
      return;
    }
    final fileSize = await file.length();
    if (fileSize > _maxImportBytes) {
      _showSnackBar(
        'File is too large. Maximum supported size is 20 MB.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _currentDocCount = 0;
      _totalDocCount = 0;
      _activeCollection = '';
    });

    try {
      final Uint8List bytes = await file.readAsBytes();
      final result = await _importService.importExcelBytes(
        bytes: bytes,
        fileName: file.path,
        targetCollection: _selectedTargetCollection,
        onProgress: (current, total, collection) {
          if (!mounted) return;
          setState(() {
            _currentDocCount = current;
            _totalDocCount = total;
            _uploadProgress = total > 0 ? current / total : 0.0;
            _activeCollection = collection;
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });

      if (result.totalUploaded > 0) {
        ref.invalidate(mobileStockListProvider);
        ref.invalidate(gadgetStockListProvider);
        ref.invalidate(salesListProvider);
        ref.invalidate(expenseListProvider);
        ref.invalidate(salaryListProvider);
        ref.invalidate(dashboardDataProvider);
        ref.invalidate(allCustomersProvider);
        ref.invalidate(customersDueListProvider);
      }

      if (mounted) _showResultDialog(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });
      if (mounted) _showSnackBar('Import failed: $e', isError: true);
    }
  }

  Future<void> _exportDataCsv() async {
    setState(() => _isExporting = true);
    try {
      final path = await ref.read(exportServiceProvider).exportToCsv();
      if (!mounted) return;
      setState(() => _isExporting = false);
      _showSnackBar('CSV files exported successfully! Saved to Downloads: $path');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      _showSnackBar('Export failed: $e', isError: true);
    }
  }

  Future<void> _exportDataExcel() async {
    setState(() => _isExporting = true);
    try {
      await ref.read(exportServiceProvider).exportToExcel();
      if (!mounted) return;
      setState(() => _isExporting = false);
      _showSnackBar('Excel backup exported successfully to Downloads folder!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      _showSnackBar('Export failed: $e', isError: true);
    }
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

  Future<void> _downloadSampleCsv(String type) async {
    try {
      final dir = await _getTargetDownloadsDirectory();
      final buffer = StringBuffer();
      String filename = '';

      if (type == 'mobile') {
        filename = 'sample_mobile_stock.csv';
        buffer.writeln('Date,Model Name,IMEI Number,Purchase Rate,Transport Cost,Selling Price,Status');
        buffer.writeln('2026-08-29,iPhone 15 Pro Max,123456789012345,115000,500,128000,unsold');
        buffer.writeln('2026-08-29,Samsung Galaxy S24,987654321098765,85000,300,94000,unsold');
      } else if (type == 'gadget') {
        filename = 'sample_gadget_stock.csv';
        buffer.writeln('Date,Product Code,Product Name,Quantity,Purchase Price,Product Cost,Selling Price,Profit Margin');
        buffer.writeln('2026-08-29,GAD-101,Apple 20W USB-C Adapter,25,1800,1850,2200,18.9');
        buffer.writeln('2026-08-29,GAD-102,Anker PowerBank 10000mAh,10,2500,2600,3200,23.0');
      } else if (type == 'sales') {
        filename = 'sample_sales.csv';
        buffer.writeln('Date,Product Type,Product ID,Product Name,Quantity,Selling Price,Total Amount,Paid Amount,Customer Name,Contact Number');
        buffer.writeln('2026-08-29,mobile,123456789012345,iPhone 15 Pro Max,1,128000,128000,128000,Rakib Hasan,01700000000');
        buffer.writeln('2026-08-29,gadget,GAD-101,Apple 20W USB-C Adapter,2,2200,4400,3000,Tanvir Ahmed,01800000000');
      } else if (type == 'expenses') {
        filename = 'sample_expenses.csv';
        buffer.writeln('Date,Category,Amount,Notes');
        buffer.writeln('2026-08-29,Shop Rent,25000,Monthly showroom rent');
        buffer.writeln('2026-08-29,Electricity Bill,3450,Office bill August');
      }

      final file = File('${dir.path}/$filename');
      await file.writeAsString(buffer.toString());
      await OpenFile.open(file.path);
      _showSnackBar('Sample CSV downloaded to Downloads folder: $filename');
    } catch (e) {
      _showSnackBar('Failed to generate sample CSV: $e', isError: true);
    }
  }

  Future<void> _runDataAudit() async {
    setState(() {
      _isAuditing = true;
    });

    try {
      await _auditService.forceServerRefresh();
      final report = await _auditService.auditAndRepairDatabase();

      if (!mounted) return;
      setState(() {
        _isAuditing = false;
      });

      if (mounted) _showAuditReportDialog(report);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAuditing = false;
      });
      if (mounted) _showSnackBar('Database audit error: $e', isError: true);
    }
  }

  void _showSnackBar(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showResultDialog(BulkImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Import Finished',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Successfully parsed ${result.totalRowsParsed} rows.'),
              const SizedBox(height: 8),
              Text(
                'Uploaded ${result.totalUploaded} records to database.',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (result.collectionCounts.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Summary per Module:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...result.collectionCounts.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('• ${entry.key}'),
                        Text(
                          '${entry.value} items',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Errors / Warnings:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    result.errors.take(5).join('\n'),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAuditReportDialog(AuditReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.cleaning_services_rounded,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Data Audit Completed',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Full database cache refreshed directly from live server.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.build_circle_outlined,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Flagged ${report.flaggedSalesCount} suspicious sales entries for review.',
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.build_circle_outlined,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Fixed ${report.repairedCustomerDuesCount} negative customer dues.',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Audit Diagnostic Log:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.logs.join('\n'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Bulk Data Import & Restore',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderBanner(),
            const SizedBox(height: 20),
            _buildDirectUploadCard(),
            const SizedBox(height: 20),
            _buildTargetCollectionDropdown(),
            const SizedBox(height: 20),
            _buildManualFilePickerSection(),
            if (_isUploading) ...[
              const SizedBox(height: 24),
              _buildProgressSection(),
            ],
            const SizedBox(height: 24),
            _buildSampleTemplatesSection(),
            const SizedBox(height: 32),
            const Divider(thickness: 1),
            const SizedBox(height: 20),
            _buildExportSection(),
            const SizedBox(height: 32),
            const Divider(thickness: 1),
            const SizedBox(height: 20),
            _buildCacheAuditSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 40),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bulk Data Import Engine',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Upload thousands of Sales, Stocks, Salaries, Expenses, or Capital entries from Excel (.xlsx) or CSV files instantly.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Direct 1-Click Upload Hero Card
  Widget _buildDirectUploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.upload_file_rounded,
              size: 44,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '1-Click Upload File',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose any Excel (.xlsx, .xls) or CSV (.csv) file to import immediately',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _isUploading ? null : _pickAndUploadFile,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(Icons.file_open_rounded, size: 22),
              label: Text(
                _isUploading
                    ? 'Uploading Data to Database...'
                    : 'Choose File & Upload Now',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualFilePickerSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tableBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Or Select File Path Manually',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceVariant,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isUploading ? null : _pickFile,
                icon: const Icon(Icons.folder_open_rounded, size: 16),
                label: const Text(
                  'Browse File',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _filePathController,
            decoration: InputDecoration(
              hintText: 'Enter or browse path to .xlsx / .csv',
              hintStyle: const TextStyle(
                color: AppColors.textHint,
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.description_rounded,
                color: AppColors.primary,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                onPressed: () => _filePathController.clear(),
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_filePathController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isUploading ? null : _startImport,
                icon: const Icon(Icons.upload_rounded, color: AppColors.primary),
                label: const Text(
                  'Upload Selected File',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTargetCollectionDropdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tableBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Target Module / Collection',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedTargetCollection ?? '',
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceVariant,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: _collectionOptions.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.value,
                child: Text(entry.key, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedTargetCollection = (val != null && val.isNotEmpty)
                    ? val
                    : null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Uploading to ${_activeCollection.isNotEmpty ? _activeCollection : 'Database'}...',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                '$_currentDocCount / $_totalDocCount records',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: AppColors.surfaceVariant,
            color: AppColors.primary,
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleTemplatesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tableBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.download_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Download Sample CSV Templates',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Generate clean pre-formatted CSV template files to easily fill with your stock or sales data:',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.phone_android_rounded, size: 16),
                label: const Text('Mobile Stock CSV'),
                onPressed: () => _downloadSampleCsv('mobile'),
              ),
              ActionChip(
                avatar: const Icon(Icons.devices_other_rounded, size: 16),
                label: const Text('Gadgets CSV'),
                onPressed: () => _downloadSampleCsv('gadget'),
              ),
              ActionChip(
                avatar: const Icon(Icons.shopping_cart_outlined, size: 16),
                label: const Text('Sales CSV'),
                onPressed: () => _downloadSampleCsv('sales'),
              ),
              ActionChip(
                avatar: const Icon(Icons.receipt_long_rounded, size: 16),
                label: const Text('Expenses CSV'),
                onPressed: () => _downloadSampleCsv('expenses'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.tableBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.file_download_outlined, color: AppColors.success, size: 22),
              SizedBox(width: 10),
              Text(
                'Export Database Records',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Export your entire active inventory, sales invoices, salaries, and expenses into CSV or Excel files.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isExporting ? null : _exportDataCsv,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.description_outlined, size: 18),
                  label: const Text(
                    'Export to CSV Files',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isExporting ? null : _exportDataExcel,
                  icon: const Icon(Icons.table_chart_outlined, size: 18),
                  label: const Text(
                    'Export to Excel (.xlsx)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCacheAuditSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.tableBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.health_and_safety_rounded, color: AppColors.info),
              SizedBox(width: 10),
              Text(
                'Database Integrity & Cache Sanitation',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'If numbers or dashboard stats look wrong due to stale offline cache or corrupted entries, run a live server refresh and database audit.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.info, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isAuditing ? null : _runDataAudit,
              icon: _isAuditing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: AppColors.info,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.sync_rounded, color: AppColors.info),
              label: Text(
                _isAuditing
                    ? 'Auditing Database...'
                    : 'Sync Live Server & Fix Data Mismatches',
                style: const TextStyle(
                  color: AppColors.info,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
