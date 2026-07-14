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
    final appUser = ref.watch(appUserProvider).value;
    final isAdmin = appUser?.isAdmin ?? false;

    return Scaffold(
      drawer: const DashboardDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, AppColors.primary.withValues(alpha: 0.04)],
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
                    // Show a simple notification history or just navigate to settings for now
                    // as there is no dedicated notification screen yet.
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
              error: (error, stack) => Center(
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
                    ElevatedButton(
                      onPressed: () => _refreshDashboard(ref),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
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
        double iconSize = 20;
        double valueFontSize = 18;
        double titleFontSize = 12;
        double childAspectRatio = 1.4;

        if (width > 1100) {
          crossAxisCount = 4;
          iconSize = 32;
          valueFontSize = 24;
          titleFontSize = 14;
          childAspectRatio = 1.3;
        } else if (width > 600) {
          crossAxisCount = 3;
          iconSize = 28;
          valueFontSize = 22;
          titleFontSize = 13;
          childAspectRatio = 1.2;
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

              const SizedBox(height: 24),

              // Summary Cards Grid (Glass Style)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
                children: [
                  _buildGlassCard(
                    context,
                    title: l10n.totalCapital,
                    value: Formatters.formatCurrency(data.totalCapital),
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.primary,
                    iconSize: iconSize,
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
                  _buildGlassCard(
                    context,
                    title: l10n.availableCapital,
                    value: Formatters.formatCurrency(data.availableCapital),
                    icon: Icons.savings_outlined,
                    color: AppColors.success,
                    iconSize: iconSize,
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
                  _buildGlassCard(
                    context,
                    title: 'Total Investment',
                    value: Formatters.formatCurrency(data.capitalInvested),
                    icon: Icons.monetization_on_outlined,
                    color: Colors.orange,
                    iconSize: iconSize,
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
                  _buildGlassCard(
                    context,
                    title: 'Total Sales Volume',
                    value: Formatters.formatCurrency(data.totalSales),
                    icon: Icons.point_of_sale_outlined,
                    color: AppColors.info,
                    iconSize: iconSize,
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
                  _buildGlassCard(
                    context,
                    title: 'Unsold Stock',
                    value: Formatters.formatCurrency(
                      data.mobileStockValue + data.gadgetStockValue,
                    ),
                    icon: Icons.inventory_2_outlined,
                    color: const Color(0xFF8B5CF6), // Vibrant Violet
                    iconSize: iconSize,
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
                  _buildGlassCard(
                    context,
                    title: l10n.totalProfit,
                    value: Formatters.formatCurrency(data.totalProfit),
                    icon: Icons.trending_up,
                    color: AppColors.success,
                    isTrend: true,
                    iconSize: iconSize,
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
                  _buildGlassCard(
                    context,
                    title: l10n.totalLoss,
                    value: Formatters.formatCurrency(data.totalLoss),
                    icon: Icons.trending_down,
                    color: AppColors.error,
                    isTrend: true,
                    iconSize: iconSize,
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
                  _buildGlassCard(
                    context,
                    title: l10n.totalBaki,
                    value: Formatters.formatCurrency(data.totalBaki),
                    icon: Icons.pending_actions_outlined,
                    color: AppColors.warning,
                    iconSize: iconSize,
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
                ],
              ),

              const SizedBox(height: 32),

              // Mobile Sector Overview
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.mobileSector,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Mobile Sector Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
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
                  _buildGlassCard(
                    context,
                    title: 'Mobile Sales',
                    value: Formatters.formatCurrency(data.mobileSales),
                    icon: Icons.smartphone,
                    color: AppColors.mobileSector,
                    iconSize: iconSize,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                  ),
                  _buildGlassCard(
                    context,
                    title: 'Units Sold',
                    value: '${data.mobileUnitsSold}',
                    icon: Icons.shopping_bag_outlined,
                    color: Colors.blueGrey,
                    iconSize: iconSize,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                  ),
                  _buildGlassCard(
                    context,
                    title: 'Mobile Profit',
                    value: Formatters.formatCurrency(data.mobileProfit),
                    icon: Icons.trending_up,
                    color: AppColors.success,
                    isTrend: true,
                    iconSize: iconSize,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                  ),
                  _buildGlassCard(
                    context,
                    title: 'Mobile Loss',
                    value: Formatters.formatCurrency(data.mobileLoss),
                    icon: Icons.trending_down,
                    color: AppColors.error,
                    isTrend: true,
                    iconSize: iconSize,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Gadget Sector Overview
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.gadgetSector,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Gadget Sector Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
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
                  _buildGlassCard(
                    context,
                    title: 'Gadget Sales',
                    value: Formatters.formatCurrency(data.gadgetSales),
                    icon: Icons.headphones,
                    color: AppColors.gadgetSector,
                    iconSize: iconSize,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                  ),
                  _buildGlassCard(
                    context,
                    title: 'Units Sold',
                    value: '${data.gadgetUnitsSold}',
                    icon: Icons.shopping_basket_outlined,
                    color: Colors.blueGrey,
                    iconSize: iconSize,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                  ),
                  _buildGlassCard(
                    context,
                    title: 'Gadget Profit',
                    value: Formatters.formatCurrency(data.gadgetProfit),
                    icon: Icons.trending_up,
                    color: AppColors.success,
                    isTrend: true,
                    iconSize: iconSize,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
                  ),
                  _buildGlassCard(
                    context,
                    title: 'Gadget Loss',
                    value: Formatters.formatCurrency(data.gadgetLoss),
                    icon: Icons.trending_down,
                    color: AppColors.error,
                    isTrend: true,
                    iconSize: iconSize,
                    valueFontSize: valueFontSize,
                    titleFontSize: titleFontSize,
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

                // Calculate category sums
                double officeRentSum = 0;
                double shopRentSum = 0;
                double extraCostSum = 0;

                for (final exp in expenses) {
                  if (exp.expenseType == 'Office rent') {
                    officeRentSum += exp.amount;
                  } else if (exp.expenseType == 'Shop rent') {
                    shopRentSum += exp.amount;
                  } else if (exp.expenseType == 'Extra cost') {
                    extraCostSum += exp.amount;
                  }
                }

                final totalSalary = data.totalSalaryPaid;

                // Combine them chronologically
                final List<_DashboardOutflowItem> outlays = [];
                for (final exp in expenses) {
                  outlays.add(_DashboardOutflowItem(
                    id: exp.id,
                    title: exp.expenseType,
                    amount: exp.amount,
                    date: exp.date,
                    notes: exp.notes.isNotEmpty ? exp.notes : 'Business Expense',
                    isSalary: false,
                  ));
                }
                for (final sal in salaries) {
                  outlays.add(_DashboardOutflowItem(
                    id: sal.id,
                    title: 'Salary: ${sal.employeeName}',
                    amount: sal.totalDeduction,
                    date: sal.date,
                    notes: sal.notes != null && sal.notes!.isNotEmpty ? sal.notes! : 'Employee Salary',
                    isSalary: true,
                  ));
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
                              width: 4,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444), // Crimson/Red for Expenses
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Expenses Overview',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                                builder: (_) => const TransactionHistoryScreen(initialTabIndex: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.history_rounded, size: 16, color: Color(0xFFEF4444)),
                          label: const Text(
                            'View History',
                            style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
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
                        _buildGlassCard(
                          context,
                          title: 'Salaries Paid',
                          value: Formatters.formatCurrency(totalSalary),
                          icon: Icons.badge_outlined,
                          color: const Color(0xFF6366F1), // Indigo
                          iconSize: iconSize,
                          valueFontSize: valueFontSize,
                          titleFontSize: titleFontSize,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TransactionHistoryScreen(initialTabIndex: 2),
                              ),
                            );
                          },
                        ),
                        _buildGlassCard(
                          context,
                          title: 'Office Rent',
                          value: Formatters.formatCurrency(officeRentSum),
                          icon: Icons.business_outlined,
                          color: const Color(0xFF0F766E), // Teal
                          iconSize: iconSize,
                          valueFontSize: valueFontSize,
                          titleFontSize: titleFontSize,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TransactionHistoryScreen(initialTabIndex: 1),
                              ),
                            );
                          },
                        ),
                        _buildGlassCard(
                          context,
                          title: 'Shop Rent',
                          value: Formatters.formatCurrency(shopRentSum),
                          icon: Icons.storefront_outlined,
                          color: const Color(0xFFD97706), // Orange
                          iconSize: iconSize,
                          valueFontSize: valueFontSize,
                          titleFontSize: titleFontSize,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TransactionHistoryScreen(initialTabIndex: 1),
                              ),
                            );
                          },
                        ),
                        _buildGlassCard(
                          context,
                          title: 'Extra Costs',
                          value: Formatters.formatCurrency(extraCostSum),
                          icon: Icons.receipt_long_outlined,
                          color: const Color(0xFFDB2777), // Pink/Rose
                          iconSize: iconSize,
                          valueFontSize: valueFontSize,
                          titleFontSize: titleFontSize,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TransactionHistoryScreen(initialTabIndex: 1),
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
                          border: Border.all(color: AppColors.divider.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 40,
                              color: AppColors.textSecondary.withValues(alpha: 0.4),
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
                                      : const Color(0xFFDB2777))); // Pink/Rose

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
                              border: Border.all(color: itemColor.withValues(alpha: 0.15)),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                                              color: itemColor.withValues(alpha: 0.1),
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
                                                      ? Icons.storefront_outlined
                                                      : Icons.receipt_long_outlined)),
                                          color: itemColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Title & Description
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                        crossAxisAlignment: CrossAxisAlignment.end,
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

  Widget _buildGlassCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isTrend = false,
    double iconSize = 20,
    double valueFontSize = 18,
    double titleFontSize = 12,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: color, size: iconSize),
                    ),
                    if (isTrend)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          color == AppColors.success
                              ? Icons.trending_up
                              : Icons.trending_down,
                          size: iconSize * 0.7,
                          color: color,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: valueFontSize,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: titleFontSize,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
