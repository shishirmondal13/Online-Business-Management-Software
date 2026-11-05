import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/utils/calculations.dart';
import '../providers/capital_provider.dart';

class CapitalManagementScreen extends ConsumerStatefulWidget {
  const CapitalManagementScreen({super.key});

  @override
  ConsumerState<CapitalManagementScreen> createState() =>
      _CapitalManagementScreenState();
}

class _CapitalManagementScreenState
    extends ConsumerState<CapitalManagementScreen> {
  final _initialController = TextEditingController();
  final _investedController = TextEditingController();
  final _recoveredController = TextEditingController();
  double _available = 0;

  @override
  void dispose() {
    _initialController.dispose();
    _investedController.dispose();
    _recoveredController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final capitalData = ref.watch(capitalProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.capital)),
      body: capitalData.when(
        data: (capital) {
          if (capital != null && _initialController.text.isEmpty) {
            _initialController.text = capital.initialCapital.toStringAsFixed(2);
            _investedController.text = capital.capitalInvested.toStringAsFixed(
              2,
            );
            _recoveredController.text = capital.capitalRecovered
                .toStringAsFixed(2);
            _available = capital.availableCapital;
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Available Capital Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.availableCapital,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Formatters.formatCurrency(_available),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildDisabledField(
                  label: l10n.initialCapital,
                  value: _initialController.text,
                  icon: Icons.account_balance,
                ),
                const SizedBox(height: 16),
                _buildDisabledField(
                  label: l10n.capitalInvested,
                  value: _investedController.text,
                  icon: Icons.add_circle_outline,
                ),
                const SizedBox(height: 16),
                _buildDisabledField(
                  label: l10n.capitalRecovered,
                  value: _recoveredController.text,
                  icon: Icons.remove_circle_outline,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _buildDisabledField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$value ৳',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
