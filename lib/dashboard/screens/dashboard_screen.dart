import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../shared/l10n/app_localizations.dart';

import '../../shared/constants/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/utils/calculations.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_drawer.dart';
import '../../mobile_sector/screens/mobile_stock_list_screen.dart';
import '../../gadget_sector/screens/gadget_stock_list_screen.dart';
import '../../mobile_sector/screens/add_edit_mobile_screen.dart';
import '../../gadget_sector/screens/add_edit_gadget_screen.dart';
import '../../sales/screens/new_sale_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../../capital/screens/capital_breakdown_screen.dart';
import '../../capital/screens/capital_management_screen.dart';
import '../../capital/screens/investment_history_screen.dart';
import '../../sales/screens/sales_list_screen.dart';
import '../../reports/screens/profit_loss_report_screen.dart';
import '../../reports/screens/transaction_history_screen.dart';
import '../../baki_due/screens/customer_due_list_screen.dart';
import 'unsold_products_screen.dart';
import 'returned_products_screen.dart';
import '../widgets/dashboard_3d_card.dart';
import '../../returns/screens/damage_history_screen.dart';
import '../../shared/services/notification_service.dart';
import '../../salary/screens/salary_payment_screen.dart';
import '../../expenses/screens/add_expense_screen.dart';
import '../../search/screens/global_search_screen.dart';

// Import providers for refresh logic
import '../../mobile_sector/providers/mobile_provider.dart';
import '../../gadget_sector/providers/gadget_provider.dart';
import '../../sales/providers/sales_provider.dart';
import '../../capital/providers/capital_provider.dart';
import '../../salary/providers/salary_provider.dart';
import '../../expenses/providers/expense_provider.dart';
import '../../returns/providers/return_provider.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../shared/constants/admin_accounts.dart';

class _DashboardOutflowItem {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String notes;
  final bool isSalary;

  _DashboardOutflowItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.notes,
    required this.isSalary,
  });
}

/// Dashboard screen - main home screen with business overview
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  NotificationService? _notificationService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        _notificationService = ref.read(notificationServiceProvider);
        await _notificationService!.startListening(userId);

        // Auto-recreate user profile document if it was deleted (e.g. database wipe)
        await ref.read(authServiceProvider).checkAndRecreateUserProfile();
      }
    });
  }

  @override
  void dispose() {
    _notificationService?.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dashboardData = ref.watch(dashboardDataProvider);
    final authUser = ref.watch(firebaseAuthProvider).currentUser;
    final appUser = ref.watch(appUserProvider).value;
    final isAdmin =
        (appUser?.isAdmin ?? false) || AdminAccounts.contains(authUser?.email);

    return Scaffold(
      drawer: const DashboardDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background,
              AppColors.primary.withValues(alpha: 0.04),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              floating: true,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: Text(
                l10n.dashboard,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              centerTitle: false,
              actions: [
                if (isAdmin)
                  IconButton(
                    icon: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AppColors.primary,
                    ),
                    tooltip: 'Admin Hub',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminDashboardScreen(),
                        ),
                      );
                    },
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GlobalSearchScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.primary,
                  ),
                  tooltip: 'Refresh Dashboard',
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _refreshDashboard(ref);
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.notifications_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifications functionality active.'),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
          body: RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              _refreshDashboard(ref);
              // Small delay to allow streams to restart
              await Future.delayed(const Duration(milliseconds: 300));
            },
            child: dashboardData.when(
              data: (data) => _buildDashboardContent(
                context,
                ref,
                data,
                l10n,
                appUser,
                isAdmin,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) {
                debugPrint('Dashboard load failed: $error\n$stack');
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        const Text('Error loading dashboard'),
                        const SizedBox(height: 8),
                        SelectableText(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _refreshDashboard(ref),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _refreshDashboard(WidgetRef ref) {
    // Invalidate the main aggregator
    ref.invalidate(dashboardDataProvider);

    // Invalidate all underlying data streams to force a fresh fetch from Firestore.
    // This is particularly important for Windows/Desktop where persistence can sometimes
    // lead to stale data if the streams are not explicitly refreshed.
    ref.invalidate(mobileStockListProvider);
    ref.invalidate(gadgetStockListProvider);
    ref.invalidate(salesListProvider);
    ref.invalidate(allCustomersProvider);
    ref.invalidate(capitalProvider);
    ref.invalidate(salaryListProvider);
    ref.invalidate(expenseListProvider);
    ref.invalidate(returnListProvider);
    ref.invalidate(damageEventListProvider);
  }

  Widget _buildDashboardContent(
    BuildContext context,
    WidgetRef ref,
    DashboardData data,
    AppLocalizations l10n,
    AppUser? appUser,
    bool isAdmin,
  ) {
    final businessName = appUser?.businessName;
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    if (hour >= 12 && hour < 17) greeting = 'Good Afternoon';
    if (hour >= 17) greeting = 'Good Evening';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 2;
        double iconSize = 24;
        double valueFontSize = 18;
        double titleFontSize = 12;
        double childAspectRatio = 1.25;

        if (width > 1200) {
          crossAxisCount = 3;
          valueFontSize = 22;
          titleFontSize = 13;
          childAspectRatio = 1.34;
        } else if (width > 750) {
          crossAxisCount = 3;
          valueFontSize = 19;
          titleFontSize = 12;
          childAspectRatio = 1.25;
        } else if (width > 520) {
          crossAxisCount = 2;
          valueFontSize = 17;
          titleFontSize = 11;
          childAspectRatio = 1.18;
        } else {
          crossAxisCount = 1;
          valueFontSize = 20;
          titleFontSize = 13;
          childAspectRatio = 1.45;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting, ${businessName ?? 'Partner'}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAdmin
                        ? 'Here is your business overview for today'
                        : 'Spectator Mode - Read Only Access',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Date / Month / Year Filter Bar
              _buildDateFilterBar(context, ref, data.filter),

              const SizedBox(height: 20),

              // Summary Cards Grid (3D Skeuomorphic Style)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
                children: [
                  Dashboard3DCard(
                    title: l10n.totalCapital,
                    value: Formatters.formatCurrency(data.totalCapital),
                    badgeIcon: Icons.account_balance_wallet_outlined,
                    type: Card3DType.totalCapital,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CapitalBreakdownScreen(),
                        ),
                      );
                    },
                  ),
                  Dashboard3DCard(
                    title: l10n.availableCapital,
                    value: Formatters.formatCurrency(data.availableCapital),
                    badgeIcon: Icons.savings_outlined,
                    type: Card3DType.availableCapital,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CapitalManagementScreen(),
                        ),
                      );
                    },
                  ),
                  Dashboard3DCard(
                    title: 'Total Investment',
                    value: Formatters.formatCurrency(data.capitalInvested),
                    badgeIcon: Icons.monetization_on_outlined,
                    type: Card3DType.totalInvestment,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InvestmentHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  Dashboard3DCard(
                    title: 'Total Sales Volume',
                    value: Formatters.formatCurrency(data.totalSales),
                    badgeIcon: Icons.point_of_sale_outlined,
                    type: Card3DType.totalSales,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SalesListScreen(),
                        ),
                      );
                    },
                  ),
                  Dashboard3DCard(
                    title: 'Unsold Stock',
                    value: Formatters.formatCurrency(
                      data.mobileStockValue + data.gadgetStockValue,
                    ),
                    badgeIcon: Icons.inventory_2_outlined,
                    type: Card3DType.unsoldStock,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UnsoldProductsScreen(),
                        ),
                      );
                    },
                  ),
                  Dashboard3DCard(
                    title: l10n.totalProfit,
                    value: Formatters.formatCurrency(data.totalProfit),
                    badgeIcon: Icons.trending_up,
                    type: Card3DType.totalProfit,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfitLossReportScreen(),
                        ),
                      );
                    },
                  ),
                  Dashboard3DCard(
                    title: l10n.totalLoss,
                    value: Formatters.formatCurrency(data.totalLoss),
                    badgeIcon: Icons.trending_down,
                    type: Card3DType.totalLoss,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfitLossReportScreen(),
                        ),
                      );
                    },
                  ),
                  Dashboard3DCard(
                    title: l10n.finalProfit,
                    value: Formatters.formatCurrency(data.netProfit),
                    badgeIcon: Icons.emoji_events_outlined,
                    type: Card3DType.finalProfit,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfitLossReportScreen(),
                        ),
                      );
                    },
                  ),
                  Dashboard3DCard(
                    title: l10n.totalBaki,
                    value: Formatters.formatCurrency(data.totalBaki),
                    badgeIcon: Icons.pending_actions_outlined,
                    type: Card3DType.totalBaki,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerDueListScreen(),
                        ),
                      );
                    },
                  ),
                  Dashboard3DCard(
                    title: 'Damaged Stock Loss',
                    value: Formatters.formatCurrency(data.totalDamageLoss),
                    badgeIcon: Icons.report_problem_outlined,
                    type: Card3DType.damagedStockLoss,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DamageHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Mobile Sector Overview
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.mobileSector.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.smartphone_rounded,
                          color: AppColors.mobileSector,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Mobile Sector Overview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReturnedProductsScreen(
                                initialSector: 'mobile',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.assignment_return_outlined,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        label: Text(
                          'Returned (${data.mobileReturnedCount})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DamageHistoryScreen(
                                initialSector: 'mobile',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.report_problem_outlined,
                          size: 16,
                          color: AppColors.error,
                        ),
                        label: Text(
                          'Damaged (${data.mobileDamagedCount})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
                children: [
                  Dashboard3DCard(
                    title: 'Mobile Sales',
                    value: Formatters.formatCurrency(data.mobileSales),
                    badgeIcon: Icons.smartphone,
                    type: Card3DType.mobileSales,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                  ),
                  Dashboard3DCard(
                    title: 'Units Sold',
                    value: '${data.mobileUnitsSold}',
                    badgeIcon: Icons.shopping_bag_outlined,
                    type: Card3DType.mobileUnits,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                  ),
                  Dashboard3DCard(
                    title: 'Mobile Profit',
                    value: Formatters.formatCurrency(data.mobileProfit),
                    badgeIcon: Icons.trending_up,
                    type: Card3DType.mobileProfit,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                  ),
                  Dashboard3DCard(
                    title: 'Mobile Loss',
                    value: Formatters.formatCurrency(data.mobileLoss),
                    badgeIcon: Icons.trending_down,
                    type: Card3DType.mobileLoss,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                  ),
                  Dashboard3DCard(
                    title: 'Returned Mobiles',
                    value: '${data.mobileReturnedCount} Items',
                    badgeIcon: Icons.assignment_return_outlined,
                    type: Card3DType.mobileReturned,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReturnedProductsScreen(
                            initialSector: 'mobile',
                          ),
                        ),
                      );
                    },
                  ),
                  Dashboard3DCard(
                    title: 'Damaged Mobiles',
                    value: '${data.mobileDamagedCount} Items',
                    badgeIcon: Icons.report_problem_outlined,
                    type: Card3DType.mobileDamaged,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DamageHistoryScreen(
                            initialSector: 'mobile',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Gadget Sector Overview
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.gadgetSector.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.headphones_rounded,
                          color: AppColors.gadgetSector,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Gadget Sector Overview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReturnedProductsScreen(
                                initialSector: 'gadget',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.assignment_return_outlined,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        label: Text(
                          'Returned (${data.gadgetReturnedQuantity})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DamageHistoryScreen(
                                initialSector: 'gadget',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.report_problem_outlined,
                          size: 16,
                          color: AppColors.error,
                        ),
                        label: Text(
                          'Damaged (${data.gadgetDamagedQuantity})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
                children: [
                  Dashboard3DCard(
                    title: 'Gadget Sales',
                    value: Formatters.formatCurrency(data.gadgetSales),
                    badgeIcon: Icons.headphones,
                    type: Card3DType.gadgetSales,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                  ),
                  Dashboard3DCard(
                    title: 'Units Sold',
                    value: '${data.gadgetUnitsSold}',
                    badgeIcon: Icons.shopping_basket_outlined,
                    type: Card3DType.gadgetUnits,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                  ),
                  Dashboard3DCard(
                    title: 'Gadget Profit',
                    value: Formatters.formatCurrency(data.gadgetProfit),
                    badgeIcon: Icons.trending_up,
                    type: Card3DType.gadgetProfit,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                  ),
                  Dashboard3DCard(
                    title: 'Gadget Loss',
                    value: Formatters.formatCurrency(data.gadgetLoss),
                    badgeIcon: Icons.trending_down,
                    type: Card3DType.gadgetLoss,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                  ),
                  Dashboard3DCard(
                    title: 'Returned Gadgets',
                    value: '${data.gadgetReturnedQuantity} Pcs',
                    badgeIcon: Icons.assignment_return_outlined,
                    type: Card3DType.gadgetReturned,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReturnedProductsScreen(
                            initialSector: 'gadget',
                          ),
                        ),
                      );
                    },
                  ),
                  Dashboard3DCard(
                    title: 'Damaged Gadgets',
                    value: '${data.gadgetDamagedQuantity} Pcs',
                    badgeIcon: Icons.report_problem_outlined,
                    type: Card3DType.gadgetDamaged,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DamageHistoryScreen(
                            initialSector: 'gadget',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Expenses Overview Section
              (() {
                // 1. Load lists of expenses and salaries in real-time
                final expensesAsync = ref.watch(expenseListProvider);
                final salariesAsync = ref.watch(salaryListProvider);

                final expenses = expensesAsync.value ?? [];
                final salaries = salariesAsync.value ?? [];

                final filter = data.filter;

                // Calculate category sums
                double officeRentSum = 0;
                double shopRentSum = 0;
                double extraCostSum = 0;

                for (final exp in expenses) {
                  if (filter.isWithinRange(exp.date)) {
                    if (exp.expenseType == 'Office rent') {
                      officeRentSum += exp.amount;
                    } else if (exp.expenseType == 'Shop rent') {
                      shopRentSum += exp.amount;
                    } else if (exp.expenseType == 'Extra cost') {
                      extraCostSum += exp.amount;
                    }
                  }
                }

                final totalSalary = data.totalSalaryPaid;

                // Combine them chronologically
                final List<_DashboardOutflowItem> outlays = [];
                for (final exp in expenses) {
                  if (filter.isWithinRange(exp.date)) {
                    outlays.add(
                      _DashboardOutflowItem(
                        id: exp.id,
                        title: exp.expenseType,
                        amount: exp.amount,
                        date: exp.date,
                        notes: exp.notes.isNotEmpty
                            ? exp.notes
                            : 'Business Expense',
                        isSalary: false,
                      ),
                    );
                  }
                }
                for (final sal in salaries) {
                  if (filter.isWithinRange(sal.date)) {
                    outlays.add(
                      _DashboardOutflowItem(
                        id: sal.id,
                        title: 'Salary: ${sal.employeeName}',
                        amount: sal.totalDeduction,
                        date: sal.date,
                        notes: sal.notes != null && sal.notes!.isNotEmpty
                            ? sal.notes!
                            : 'Employee Salary',
                        isSalary: true,
                      ),
                    );
                  }
                }

                // Sort chronological descending
                outlays.sort((a, b) => b.date.compareTo(a.date));

                // Take top 5
                final recentOutlays = outlays.take(5).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Expenses Overview Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.payments_outlined,
                                color: Color(0xFFEF4444),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Expenses Overview',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TransactionHistoryScreen(
                                  initialTabIndex: 1,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.history_rounded,
                            size: 16,
                            color: Color(0xFFEF4444),
                          ),
                          label: const Text(
                            'View History',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Expense Categories Grid (Salary, Office Rent, Shop Rent, Extra Cost)
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: childAspectRatio,
                      children: [
                        Dashboard3DCard(
                          title: 'Salaries Paid',
                          value: Formatters.formatCurrency(totalSalary),
                          badgeIcon: Icons.badge_outlined,
                          type: Card3DType.salaryExpense,
                          valueFontSize: valueFontSize,
                          titleFontSize: titleFontSize,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TransactionHistoryScreen(
                                  initialTabIndex: 2,
                                ),
                              ),
                            );
                          },
                        ),
                        Dashboard3DCard(
                          title: 'Office Rent',
                          value: Formatters.formatCurrency(officeRentSum),
                          badgeIcon: Icons.business_outlined,
                          type: Card3DType.officeRentExpense,
                          valueFontSize: valueFontSize,
                          titleFontSize: titleFontSize,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TransactionHistoryScreen(
                                  initialTabIndex: 1,
                                ),
                              ),
                            );
                          },
                        ),
                        Dashboard3DCard(
                          title: 'Shop Rent',
                          value: Formatters.formatCurrency(shopRentSum),
                          badgeIcon: Icons.storefront_outlined,
                          type: Card3DType.shopRentExpense,
                          valueFontSize: valueFontSize,
                          titleFontSize: titleFontSize,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TransactionHistoryScreen(
                                  initialTabIndex: 1,
                                ),
                              ),
                            );
                          },
                        ),
                        Dashboard3DCard(
                          title: 'Extra Costs',
                          value: Formatters.formatCurrency(extraCostSum),
                          badgeIcon: Icons.receipt_long_outlined,
                          type: Card3DType.extraCostExpense,
                          valueFontSize: valueFontSize,
                          titleFontSize: titleFontSize,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TransactionHistoryScreen(
                                  initialTabIndex: 1,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Recent Outlays Title
                    Text(
                      'Recent Outlays',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Outflows List (Glass Cards list style)
                    if (recentOutlays.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.divider.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 40,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No outlays recorded yet.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentOutlays.length,
                        itemBuilder: (context, index) {
                          final item = recentOutlays[index];
                          final itemColor = item.isSalary
                              ? const Color(0xFF6366F1) // Indigo
                              : (item.title == 'Office rent'
                                    ? const Color(0xFF0F766E) // Teal
                                    : (item.title == 'Shop rent'
                                          ? const Color(0xFFD97706) // Orange
                                          : const Color(
                                              0xFFDB2777,
                                            ))); // Pink/Rose

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  itemColor.withValues(alpha: 0.08),
                                  itemColor.withValues(alpha: 0.01),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: itemColor.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TransactionHistoryScreen(
                                        initialTabIndex: item.isSalary ? 2 : 1,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      // Icon Circle
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: itemColor.withValues(
                                                alpha: 0.1,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          item.isSalary
                                              ? Icons.badge_outlined
                                              : (item.title == 'Office rent'
                                                    ? Icons.business_outlined
                                                    : (item.title == 'Shop rent'
                                                          ? Icons
                                                                .storefront_outlined
                                                          : Icons
                                                                .receipt_long_outlined)),
                                          color: itemColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Title & Description
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item.notes,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Amount & Date
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '- ${Formatters.formatCurrency(item.amount)}',
                                            style: const TextStyle(
                                              color: AppColors.error,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            Formatters.formatDate(item.date),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textHint,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                );
              })(),

              const SizedBox(height: 32),

              // Sectors Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Inventory Sectors',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward, size: 20),
                    onPressed: () {},
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              AppSectorCard(
                title: l10n.mobileSector,
                stockValue: Formatters.formatCurrency(data.mobileStockValue),
                quantity: '${data.mobileUnsoldCount} ${l10n.unsold}',
                icon: Icons.smartphone_outlined,
                color: AppColors.mobileSector,
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MobileStockListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              AppSectorCard(
                title: l10n.gadgetSector,
                stockValue: Formatters.formatCurrency(data.gadgetStockValue),
                quantity: '${data.gadgetTotalQuantity} items',
                icon: Icons.headphones_outlined,
                color: AppColors.gadgetSector,
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GadgetStockListScreen(),
                    ),
                  );
                },
              ),

              if (appUser?.canEdit ?? false) ...[
                const SizedBox(height: 32),

                // New Sale Button
                Container(
                  width: double.infinity,
                  height: 60,
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
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NewSaleScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_shopping_cart,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.newSale.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Quick Actions
                Text(
                  l10n.quickActions,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppQuickActionButton(
                        text: l10n.addMobileStock,
                        icon: Icons.add_to_photos_outlined,
                        color: AppColors.mobileSector,
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddEditMobileScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppQuickActionButton(
                        text: l10n.addGadgetStock,
                        icon: Icons.add_circle_outline,
                        color: AppColors.gadgetSector,
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddEditGadgetScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppQuickActionButton(
                        text: 'Pay Salary',
                        icon: Icons.payments_rounded,
                        color: const Color(0xFF6366F1), // Indigo
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SalaryPaymentScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppQuickActionButton(
                        text: 'Extra Cost',
                        icon: Icons.receipt_long_rounded,
                        color: const Color(0xFFF59E0B), // Amber
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddExpenseScreen(
                                initialExpenseType: 'Extra cost',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }



  Widget _buildDateFilterBar(
    BuildContext context,
    WidgetRef ref,
    DashboardFilter currentFilter,
  ) {
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.filter_alt_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Period Filter',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: currentFilter.isFiltered
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: currentFilter.isFiltered
                              ? AppColors.primary
                              : AppColors.tableBorder,
                        ),
                      ),
                      child: Text(
                        currentFilter.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: currentFilter.isFiltered
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (currentFilter.isFiltered)
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(dashboardFilterProvider.notifier).state =
                        const DashboardFilter(label: 'All Time');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.refresh_rounded,
                          size: 14,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Reset',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  label: 'All Time',
                  isSelected: currentFilter.label == 'All Time',
                  icon: Icons.all_inclusive_rounded,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(dashboardFilterProvider.notifier).state =
                        const DashboardFilter(label: 'All Time');
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Today',
                  isSelected: currentFilter.label == 'Today',
                  icon: Icons.today_rounded,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final today = DateTime(now.year, now.month, now.day);
                    ref
                        .read(dashboardFilterProvider.notifier)
                        .state = DashboardFilter(
                      fromDate: today,
                      toDate: today,
                      label: 'Today',
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'This Month',
                  isSelected: currentFilter.label == 'This Month',
                  icon: Icons.calendar_view_month_rounded,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final first = DateTime(now.year, now.month, 1);
                    final lastDay = DateTime(now.year, now.month + 1, 0).day;
                    final last = DateTime(
                      now.year,
                      now.month,
                      lastDay,
                      23,
                      59,
                      59,
                    );
                    ref
                        .read(dashboardFilterProvider.notifier)
                        .state = DashboardFilter(
                      fromDate: first,
                      toDate: last,
                      label: 'This Month',
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'This Year',
                  isSelected: currentFilter.label == 'This Year',
                  icon: Icons.calendar_today_rounded,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final first = DateTime(now.year, 1, 1);
                    final last = DateTime(now.year, 12, 31, 23, 59, 59);
                    ref
                        .read(dashboardFilterProvider.notifier)
                        .state = DashboardFilter(
                      fromDate: first,
                      toDate: last,
                      label: 'This Year',
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Pick Month / Year',
                  isSelected: false,
                  icon: Icons.edit_calendar_rounded,
                  isAction: true,
                  onTap: () => _showMonthYearPicker(context, ref),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Custom Range',
                  isSelected: false,
                  icon: Icons.date_range_rounded,
                  isAction: true,
                  onTap: () => _showCustomRangePicker(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
    bool isAction = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isAction
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.background),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.tableBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMonthYearPicker(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    int selectedMonth =
        ref.read(dashboardFilterProvider).fromDate?.month ?? now.month;
    int selectedYear =
        ref.read(dashboardFilterProvider).fromDate?.year ?? now.year;

    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text(
                    'Select Month & Year',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: selectedMonth,
                    decoration: InputDecoration(
                      labelText: 'Month',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.date_range_rounded),
                    ),
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text(months[index]),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedMonth = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: selectedYear,
                    decoration: InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.history_rounded),
                    ),
                    items: List.generate(11, (index) {
                      final year = now.year - 5 + index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text('$year'),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedYear = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final fromDate = DateTime(selectedYear, selectedMonth, 1);
                    final lastDay = DateTime(
                      selectedYear,
                      selectedMonth + 1,
                      0,
                    ).day;
                    final toDate = DateTime(
                      selectedYear,
                      selectedMonth,
                      lastDay,
                      23,
                      59,
                      59,
                    );

                    ref
                        .read(dashboardFilterProvider.notifier)
                        .state = DashboardFilter(
                      fromDate: fromDate,
                      toDate: toDate,
                      label: '${months[selectedMonth - 1]} $selectedYear',
                    );

                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Apply Filter',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showCustomRangePicker(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final from = picked.start;
      final to = picked.end;
      final label =
          '${from.day}/${from.month}/${from.year} - ${to.day}/${to.month}/${to.year}';

      ref.read(dashboardFilterProvider.notifier).state = DashboardFilter(
        fromDate: from,
        toDate: to,
        label: label,
      );
    }
  }
}
