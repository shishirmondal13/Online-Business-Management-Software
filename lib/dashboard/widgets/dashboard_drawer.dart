import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../shared/l10n/app_localizations.dart';

import '../../shared/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mobile_sector/screens/mobile_stock_list_screen.dart';
import '../../gadget_sector/screens/gadget_stock_list_screen.dart';
import '../../transport/screens/transport_setup_screen.dart';
import '../../sales/screens/sales_list_screen.dart';
import '../../baki_due/screens/customer_due_list_screen.dart';
import '../../reports/screens/transaction_history_screen.dart';
import '../../reports/screens/profit_loss_report_screen.dart';
import '../../expenses/providers/expense_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../settings/screens/settings_screen.dart';
import '../../salary/screens/employee_list_screen.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../search/screens/global_search_screen.dart';
import '../../mobile_sector/providers/mobile_provider.dart';
import '../../gadget_sector/providers/gadget_provider.dart';
import '../../sales/providers/sales_provider.dart';
import '../../capital/providers/capital_provider.dart';
import '../../salary/providers/salary_provider.dart';

/// Dashboard navigation drawer
class DashboardDrawer extends ConsumerWidget {
  const DashboardDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final appUserAsync = ref.watch(appUserProvider);
    final appUser = appUserAsync.value;
    final isAdmin = appUser?.isAdmin ?? false;

    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          // Custom Header with Gradient
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 24,
              left: 20,
              right: 20,
            ),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.store_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  appUser?.businessName ?? 'Business',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.appName.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _DrawerItem(
                  icon: Icons.dashboard_rounded,
                  title: l10n.dashboard,
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerItem(
                  icon: Icons.refresh_rounded,
                  title: 'Refresh App',
                  color: AppColors.primary,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                    // Invalidate all main providers
                    ref.invalidate(appUserProvider);
                    ref.invalidate(dashboardDataProvider);
                    ref.invalidate(mobileStockListProvider);
                    ref.invalidate(gadgetStockListProvider);
                    ref.invalidate(salesListProvider);
                    ref.invalidate(expenseListProvider);
                    ref.invalidate(capitalProvider);
                    ref.invalidate(salaryListProvider);
                    ref.invalidate(allCustomersProvider);
                    // Show a small feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('App data refreshed'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                if (isAdmin)
                  _DrawerItem(
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Admin Hub',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminDashboardScreen(),
                        ),
                      );
                    },
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Divider(color: AppColors.divider),
                ),

                _DrawerSectionTitle(title: 'Inventory'),
                _DrawerItem(
                  icon: Icons.smartphone_rounded,
                  title: l10n.mobileStock,
                  color: AppColors.mobileSector,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MobileStockListScreen(),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.headphones_rounded,
                  title: l10n.gadgetStock,
                  color: AppColors.gadgetSector,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GadgetStockListScreen(),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.local_shipping_rounded,
                  title: l10n.transport,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TransportSetupScreen(),
                      ),
                    );
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Divider(color: AppColors.divider),
                ),

                _DrawerSectionTitle(title: 'Operations'),
                _DrawerItem(
                  icon: Icons.receipt_long_rounded,
                  title: l10n.sales,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SalesListScreen(),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.pending_rounded,
                  title: l10n.bakiDue,
                  color: AppColors.warning,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CustomerDueListScreen(),
                      ),
                    );
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Divider(color: AppColors.divider),
                ),

                _DrawerSectionTitle(title: 'Insights & Capital'),
                _DrawerItem(
                  icon: Icons.history_rounded,
                  title: 'Transaction History',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TransactionHistoryScreen(),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.analytics_rounded,
                  title: l10n.reports,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfitLossReportScreen(),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.badge_rounded,
                  title: 'Employees',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EmployeeListScreen(),
                      ),
                    );
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Divider(color: AppColors.divider),
                ),

                _DrawerSectionTitle(title: 'App'),
                _DrawerItem(
                  icon: Icons.search_rounded,
                  title: l10n.search,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GlobalSearchScreen(),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.settings_rounded,
                  title: l10n.settings,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              title: Text(
                l10n.logout,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onTap: () async {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                await ref.read(authNotifierProvider.notifier).logout();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerSectionTitle extends StatelessWidget {
  final String title;

  const _DrawerSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final VoidCallback? onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: color ?? AppColors.textSecondary, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}
